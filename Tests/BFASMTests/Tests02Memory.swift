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
    
//    func test03MemoryRead() {
//        measure {
//            genericMemoryRead(0x1010, value: 0x1020)
//        }
//    }
//    
//    func test04MemoryWrite() {
//        measure {
//            genericMemoryWrite(0x1010, value: 0x1020)
//        }
//    }
    
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
                XCTAssert(memory.register16Value(vm.memory.firstCell.address) == address)
            },
            Memory.memoryBreakPointBigMove: { memory, pointer in
                count += 256
                let cell = memory.getMemoryCell(index: count)
                assert(memory[memory.getMemoryCell(index: count).backFlagIndex] == 1)
                assert(pointer == cell.nextFlagIndex)
            },
            Memory.memoryBreakPointLittleMove: { memory, pointer in
                count += 1
                let cell = memory.getMemoryCell(index: count)
                assert(memory[memory.getMemoryCell(index: count).backFlagIndex] == 2)
                assert(pointer == cell.nextFlagIndex)
            },
            Memory.memoryBreakPointBigBack: { memory, pointer in
                count -= 256
                let cell = memory.getMemoryCell(index: count)
                assert(pointer == cell.backFlagIndex)
            },
            Memory.memoryBreakPointLittleBack: { memory, pointer in
                count -= 1
                let cell = memory.getMemoryCell(index: count)
                assert(pointer == cell.address.highCell.index)
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
        }
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
                assert(memory.register16Value(vm.memory.firstCell.address) == address)
            },
            Memory.memoryBreakPointBigMove: { memory, pointer in
                count += 256
                let cell = memory.getMemoryCell(index: count)
                assert(memory[memory.getMemoryCell(index: count).backFlagIndex] == 1)
                assert(memory.getValue(cell.moveData) == value)
                assert(pointer == cell.nextFlagIndex)
            },
            Memory.memoryBreakPointLittleMove: { memory, pointer in
                count += 1
                let cell = memory.getMemoryCell(index: count)
                assert(memory[memory.getMemoryCell(index: count).backFlagIndex] == 2)
                assert(memory.getValue(cell.moveData) == value)
                assert(pointer == cell.nextFlagIndex)
            },
            Memory.memoryBreakPointBigBack: { memory, pointer in
                count -= 256
                let cell = memory.getMemoryCell(index: count)
                assert(pointer == cell.backFlagIndex)
            },
            Memory.memoryBreakPointLittleBack: { memory, pointer in
                count -= 1
                let cell = memory.getMemoryCell(index: count)
                assert(pointer == cell.address.highCell.index)
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
        
        XCTAssert(count == 0)
        let cell0 = memory.getMemoryCell(vm, index: Int(address))
        XCTAssert(memory.getValue(cell0.data) == value)
        XCTAssert(memory.checkRegister16Value(vm.register1, value: value))
    }
}
