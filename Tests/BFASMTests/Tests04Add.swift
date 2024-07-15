import XCTest
@testable import BFASM
    
class Tests04Add: XCTestCase {
    func test01BaseAdd() {
        var memory: [UInt8] = .init(repeating: 0, count: 256 * 256)
        let vm = VirtualMachine()
        brainfuckInterpreter(&memory) {
            vm.initMemory()
        }
        
        checkAdd(reg1: vm.register0, reg2: vm.register1, a: 0x0000, b: 0x0000, save: true, memory: &memory)
        checkAdd(reg1: vm.register0, reg2: vm.register1, a: 0x0001, b: 0x0000, save: true, memory: &memory)
        checkAdd(reg1: vm.register0, reg2: vm.register1, a: 0x0100, b: 0x0000, save: true, memory: &memory)
        checkAdd(reg1: vm.register0, reg2: vm.register1, a: 0x0000, b: 0x0001, save: true, memory: &memory)
        checkAdd(reg1: vm.register0, reg2: vm.register1, a: 0x0000, b: 0x0010, save: true, memory: &memory)
        checkAdd(reg1: vm.register0, reg2: vm.register1, a: 0x1020, b: 0x3070, save: true, memory: &memory)
        checkAdd(reg1: vm.register0, reg2: vm.register1, a: 0x1020, b: 0x30FF, save: true, memory: &memory)
        checkAdd(reg1: vm.register0, reg2: vm.register1, a: 0x10FF, b: 0x3070, save: true, memory: &memory)
        checkAdd(reg1: vm.register0, reg2: vm.register1, a: 0xFF20, b: 0x3070, save: true, memory: &memory)
        checkAdd(reg1: vm.register0, reg2: vm.register1, a: 0xFFFF, b: 0x0001, save: true, memory: &memory)

        checkAdd(reg1: vm.register0, reg2: vm.register1, a: 0x0000, b: 0x0000, save: false, memory: &memory)
        checkAdd(reg1: vm.register0, reg2: vm.register1, a: 0x0001, b: 0x0000, save: false, memory: &memory)
        checkAdd(reg1: vm.register0, reg2: vm.register1, a: 0x0100, b: 0x0000, save: false, memory: &memory)
        checkAdd(reg1: vm.register0, reg2: vm.register1, a: 0x0000, b: 0x0001, save: false, memory: &memory)
        checkAdd(reg1: vm.register0, reg2: vm.register1, a: 0x0000, b: 0x0010, save: false, memory: &memory)
        checkAdd(reg1: vm.register0, reg2: vm.register1, a: 0x1020, b: 0x3070, save: false, memory: &memory)
        checkAdd(reg1: vm.register0, reg2: vm.register1, a: 0x1020, b: 0x30FF, save: false, memory: &memory)
        checkAdd(reg1: vm.register0, reg2: vm.register1, a: 0x10FF, b: 0x3070, save: false, memory: &memory)
        checkAdd(reg1: vm.register0, reg2: vm.register1, a: 0xFF20, b: 0x3070, save: false, memory: &memory)
        
        checkAdd(reg1: vm.register0, reg2: vm.register1, a: 0xFFFF, b: 0x0001, save: false, memory: &memory)
    }
    
    func test02ConstAdd() {
        var memory: [UInt8] = .init(repeating: 0, count: 256 * 256)
        let vm = VirtualMachine()
        brainfuckInterpreter(&memory) {
            vm.initMemory()
        }
        
        checkAdd(reg1: vm.register0, a: 0x0000, b: 0x0000, memory: &memory)
        checkAdd(reg1: vm.register0, a: 0x0001, b: 0x0000, memory: &memory)
        checkAdd(reg1: vm.register0, a: 0x0100, b: 0x0000, memory: &memory)
        checkAdd(reg1: vm.register0, a: 0x0000, b: 0x0001, memory: &memory)
        checkAdd(reg1: vm.register0, a: 0x0000, b: 0x0010, memory: &memory)
        checkAdd(reg1: vm.register0, a: 0x1020, b: 0x0070, memory: &memory)
        checkAdd(reg1: vm.register0, a: 0x1020, b: 0x00FF, memory: &memory)
        checkAdd(reg1: vm.register0, a: 0x10FF, b: 0x0070, memory: &memory)
        checkAdd(reg1: vm.register0, a: 0xFF20, b: 0x0070, memory: &memory)
        checkAdd(reg1: vm.register0, a: 0xFFFF, b: 0x0001, memory: &memory)
        checkAdd(reg1: vm.register0, a: 370, b: 3, memory: &memory)

        checkAdd(reg1: vm.register0, reg2: vm.register1, a: 0xFFFF, b: 0x0001, save: false, memory: &memory)
    }
    
    private func checkAdd(reg1: BigRegister16, a: UInt16, b: UInt8, memory: inout [UInt8]) {
        memory.setRegister16Value(reg1, value: a)
        
        brainfuckInterpreter(&memory) {
            reg1.addConst(b)
        }
        
        let value = (Int(a) + Int(b)) % (0xFFFF + 1)
        XCTAssert(memory.checkRegister16Value(reg1, value: UInt16(value)))
    }
    
    private func checkAdd(reg1: BigRegister16, reg2: BigRegister16, a: UInt16, b: UInt16, save: Bool, memory: inout [UInt8]) {
        memory.setRegister16Value(reg1, value: a)
        memory.setRegister16Value(reg2, value: b)
        
        brainfuckInterpreter(&memory) {
            reg1.add(reg2, saveOperand: save)
        }
        
        XCTAssert(memory.checkRegister16Value(reg1, value: UInt16((Int(a) + Int(b)) % (0xFFFF + 1))))
        if save {
            XCTAssert(memory.checkRegister16Value(reg2, value: b))
        } else {
            XCTAssert(memory.checkRegister16Value(reg2, value: 0x0000))
        }
    }
}
