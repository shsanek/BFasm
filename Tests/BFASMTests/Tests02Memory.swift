import XCTest
@testable import BFASM
    
class Tests02Memory: XCTestCase {
    func test01MemoryRead() {
        genericMemoryRead(0x0010, value: 0x1020)
        genericMemoryRead(0x0000, value: 0x1020)
        genericMemoryRead(0x0400, value: 0x1020)
        genericMemoryRead(0x0100, value: 0x1020)
        genericMemoryRead(0x0101, value: 0x1020)
        genericMemoryRead(0x0001, value: 0x1020)
        genericMemoryRead(0x1010, value: 0x1020)
    }
    
    func test02MemoryWrite() {
        genericMemoryWrite(0x0010, value: 0x1020)
        genericMemoryWrite(0x0000, value: 0x1020)
        genericMemoryWrite(0x0400, value: 0x1020)
        genericMemoryWrite(0x0100, value: 0x1020)
        genericMemoryWrite(0x0101, value: 0x1020)
        genericMemoryWrite(0x0001, value: 0x1020)
        genericMemoryWrite(0x1010, value: 0x1020)
    }
    
    
    func test03Memory() {
        genericProcess(256, value: 0x1020, command: 0)
        genericProcess(0x0000, value: 0x1020, command: 0)
        genericProcess(0x0400, value: 0x1020, command: 0)
        genericProcess(0x0100, value: 0x1020, command: 0)
        genericProcess(0x0101, value: 0x1020, command: 0)
        genericProcess(0x0001, value: 0x1020, command: 0)
        genericProcess(0x1010, value: 0x1020, command: 0)
        
        genericProcess(256, value: 0x1020, command: 1)
        genericProcess(0x0000, value: 0x1020, command: 1)
        genericProcess(0x0400, value: 0x1020, command: 1)
        genericProcess(0x0100, value: 0x1020, command: 1)
        genericProcess(0x0101, value: 0x1020, command: 1)
        genericProcess(0x0001, value: 0x1020, command: 1)
        genericProcess(0x1010, value: 0x1020, command: 1)
    }
    
    func genericMemoryRead(_ address: UInt16, value: UInt16) {
        var memory: [UInt8] = .init(repeating: 0, count: 256 * 256 * 256)
        let vm = VirtualMachine()
        let code = body {
            vm.initMemory()
        }
        brainfuckInterpreter(code: code, memory: &memory)
        
        let cell0 = memory.getMemoryCell(vm, index: Int(address))
        
        memory.setValue(cell0.data, value: value)
        memory.setRegister16Value(vm.register0, value: address)
        
        var count = 0
        
        brainfuckInterpreter(&memory, breakPoints: [
            Memory.memoryBreakPointInit: { memory, _ in
                assert(vm.memory.firstCell.address.value(&memory) == address)
            },
            Memory.memoryBreakPointBigMove: { memory, pointer in
                count += 256
                let cell = memory.getMemoryCell(index: count)
                assert(cell.flags.highValue == pointer)
                assert(memory[cell.flags.highValue] == 1)
                assert(memory[cell.flags.lowValue] == 0)
            },
            Memory.memoryBreakPointLittleMove: { memory, pointer in
                count += 1
                let cell = memory.getMemoryCell(index: count)
                assert(cell.flags.lowValue == pointer)
                assert(memory[cell.flags.highValue] == 0)
                assert(memory[cell.flags.lowValue] == 1)
            },
            Memory.memoryBreakPointBigBack: { memory, pointer in
                count -= 256
                let cell = memory.getMemoryCell(index: count)
                assert(cell.flags.highValue == pointer)
            },
            Memory.memoryBreakPointLittleBack: { memory, pointer in
                count -= 1
                let cell = memory.getMemoryCell(index: count)
                assert(cell.flags.lowValue == pointer)
            },
            Memory.memoryBreakPointEndMove: { memory, pointer in
                let cell = memory.getMemoryCell(index: count)
                assert(memory.getValue(cell.data) == value)
                assert(memory.getValue(cell.moveData) == value)

                assert(pointer == cell.index)
                
                XCTAssert(count == address)
            }
        ]) {
            vm.memory.readValue(address: vm.register0, value: vm.register1)
            SetCell(0)
            CustomBreakPoint { memory, currentPoint in
                XCTAssert(currentPoint == 0)
            }
        }
        XCTAssert(memory.validMemory(vm))
        XCTAssert(count == 0)
        XCTAssert(memory.checkRegister16Value(vm.register1, value: value))
    }

    func genericMemoryWrite(_ address: UInt16, value: UInt16) {
        var memory: [UInt8] = .init(repeating: 0, count: 256 * 256 * 256)
        let vm = VirtualMachine()
        let code = body {
            vm.initMemory()
        }
        brainfuckInterpreter(code: code, memory: &memory)
        
        memory.setRegister16Value(vm.register0, value: address)
        memory.setRegister16Value(vm.register1, value: value)

        var count = 0
        
        brainfuckInterpreter(&memory, breakPoints: [
            Memory.memoryBreakPointInit: { memory, _ in
                assert(memory.getValue(vm.memory.firstCell.moveData) == value)
                assert(vm.memory.firstCell.address.value(&memory) == address)
            },
            Memory.memoryBreakPointBigMove: { memory, pointer in
                count += 256
                let cell = memory.getMemoryCell(index: count)
                assert(memory[memory.getMemoryCell(index: count).flags.highValue] == 1)
                assert(memory[memory.getMemoryCell(index: count).flags.lowValue] == 0)
                assert(memory.getValue(cell.moveData) == value)
            },
            Memory.memoryBreakPointLittleMove: { memory, pointer in
                count += 1
                let cell = memory.getMemoryCell(index: count)
                assert(memory[memory.getMemoryCell(index: count).flags.highValue] == 0)
                assert(memory[memory.getMemoryCell(index: count).flags.lowValue] == 1)
                assert(memory.getValue(cell.moveData) == value)
            },
            Memory.memoryBreakPointBigBack: { memory, pointer in
                count -= 256
                let cell = memory.getMemoryCell(index: count)
                assert(cell.flags.highValue == pointer)
            },
            Memory.memoryBreakPointLittleBack: { memory, pointer in
                count -= 1
                let cell = memory.getMemoryCell(index: count)
                assert(cell.flags.lowValue == pointer)
            },
            Memory.memoryBreakPointEndMove: { memory, pointer in
                let cell = memory.getMemoryCell(index: count)
                assert(memory.getValue(cell.data) == value)
                assert(memory.getValue(cell.moveData) == 0)

                assert(pointer == cell.index)
                
                XCTAssert(count == address)
            }
        ]) {
            vm.memory.writeValue(address: vm.register0, value: vm.register1)
        }
        XCTAssert(memory.validMemory(vm))
        XCTAssert(count == 0)
        let cell0 = memory.getMemoryCell(vm, index: Int(address))
        XCTAssert(memory.getValue(cell0.data) == value)
        XCTAssert(memory.checkRegister16Value(vm.register1, value: value))
    }
    
    func genericProcess(_ address: UInt16, value: UInt16, command: Int) {
        var memory: [UInt8] = .init(repeating: 0, count: 256 * 256 * 256)
        let vm = VirtualMachine()
        let code = body {
            vm.initMemory()
        }
        brainfuckInterpreter(code: code, memory: &memory)
        
        var count = 0
        
        let cell0 = memory.getMemoryCell(vm, index: Int(address))
        memory.setValue(cell0.data, value: value)
        memory.setRegister16Value(vm.register0, value: address)
        
        memory.setRegister16Value(vm.register0, value: address)
        memory.setRegister16Value(vm.register1, value: (command == 1) ? value : 0)
        memory.setRegister16Value(vm.register2, value: UInt16(command))
    
        brainfuckInterpreter(&memory, breakPoints: [
            Memory.memoryBreakPointInit: { memory, _ in
                assert(vm.memory.firstCell.address.value(&memory) == address)
                if command == 1 {
                    assert(memory.getValue(vm.memory.firstCell.moveData) == value)
                } else {
                    assert(memory.getValue(vm.memory.firstCell.moveData) == 0)
                }
            },
            Memory.memoryBreakPointBigMove: { memory, pointer in
                count += 256
                let cell = memory.getMemoryCell(index: count)
                assert(memory[memory.getMemoryCell(index: count).flags.highValue] == 1)
                assert(memory[memory.getMemoryCell(index: count).flags.lowValue] == 0)
                if command == 1 {
                    assert(memory.getValue(cell.moveData) == value)
                } else {
                    assert(memory.getValue(cell.moveData) == 0)
                }
            },
            Memory.memoryBreakPointLittleMove: { memory, pointer in
                count += 1
                let cell = memory.getMemoryCell(index: count)
                assert(memory[memory.getMemoryCell(index: count).flags.highValue] == 0)
                assert(memory[memory.getMemoryCell(index: count).flags.lowValue] == 1)
                if command == 1 {
                    assert(memory.getValue(cell.moveData) == value)
                } else {
                    assert(memory.getValue(cell.moveData) == 0)
                }
            },
            Memory.memoryBreakPointBigBack: { memory, pointer in
                count -= 256
                let cell = memory.getMemoryCell(index: count)
                assert(cell.flags.highValue == pointer)
            },
            Memory.memoryBreakPointLittleBack: { memory, pointer in
                count -= 1
                let cell = memory.getMemoryCell(index: count)
                assert(cell.flags.lowValue == pointer)
            },
            Memory.memoryBreakPointEndMove: { memory, pointer in
                let cell = memory.getMemoryCell(index: count)
                if command == 1 {
                    assert(memory.getValue(cell.data) == value)
                    assert(memory.getValue(cell.moveData) == 0)
                } else {
                    assert(memory.getValue(cell.data) == value)
                    assert(memory.getValue(cell.moveData) == value)
                }
                assert(pointer == cell.index)
                XCTAssert(count == address)
            }
        ]) {
            vm.register0.move(to: vm.r0)
            if command == 1 {
                vm.register1.move(to: vm.r1)
                CustomBreakPoint { memory, currentPoint in
                    assert(vm.r1.value(&memory) == value)
                }
            }
            vm.memory.memoryProcess(address: vm.r0, value: vm.r1, commandIndex: vm.register2.lowCell.value)
        }

        
        XCTAssert(count == 0)
        if command == 1 {
            XCTAssert(memory.getValue(cell0.data) == value)
        } else {
            XCTAssert(vm.r1.value(&memory) == value)
        }
    }
}
