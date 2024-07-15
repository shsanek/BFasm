import XCTest
@testable import BFASM
    
class Tests04Mul: XCTestCase {
    func test01BaseMul() {
        var memory: [UInt8] = .init(repeating: 0, count: 256 * 256)
        let vm = VirtualMachine()
        brainfuckInterpreter(&memory) {
            vm.initMemory()
        }
        
        checkMul(reg1: vm.register0, a: 0xF000, b: 0x01, inline: false, memory: &memory)
        checkMul(reg1: vm.register0, a: 0x0010, b: 0x03, inline: false, memory: &memory)
        checkMul(reg1: vm.register0, a: 0x0020, b: 0x04, inline: false, memory: &memory)
        checkMul(reg1: vm.register0, a: 0x0010, b: 0x05, inline: false, memory: &memory)
        checkMul(reg1: vm.register0, a: 0x0020, b: 0x06, inline: false, memory: &memory)
        checkMul(reg1: vm.register0, a: 0x0010, b: 0x07, inline: false, memory: &memory)
        checkMul(reg1: vm.register0, a: 0x0000, b: 0x20, inline: false, memory: &memory)
        checkMul(reg1: vm.register0, a: 0x0011, b: 0x20, inline: false, memory: &memory)
        checkMul(reg1: vm.register0, a: 0x7011, b: 0x20, inline: false, memory: &memory)
        checkMul(reg1: vm.register0, a: 0x0001, b: 0x20, inline: false, memory: &memory)
        checkMul(reg1: vm.register0, a: 37, b: 10, inline: false, memory: &memory)
    }
    
    func test02Mul() {
        var memory: [UInt8] = .init(repeating: 0, count: 256 * 256)
        let vm = VirtualMachine()
        brainfuckInterpreter(&memory) {
            vm.initMemory()
        }
        
        checkMul(reg1: vm.register0, reg2: vm.register1, a: 0x0000, b: 0x0000, vm: vm, memory: &memory)
        checkMul(reg1: vm.register0, reg2: vm.register1, a: 0x0001, b: 0x0000, vm: vm, memory: &memory)
        checkMul(reg1: vm.register0, reg2: vm.register1, a: 0x0100, b: 0x0000, vm: vm, memory: &memory)
        checkMul(reg1: vm.register0, reg2: vm.register1, a: 0x0002, b: 0x0001, vm: vm, memory: &memory)
        checkMul(reg1: vm.register0, reg2: vm.register1, a: 0x0002, b: 0x0010, vm: vm, memory: &memory)
        checkMul(reg1: vm.register0, reg2: vm.register1, a: 0x1020, b: 0x3070, vm: vm, memory: &memory)
        checkMul(reg1: vm.register0, reg2: vm.register1, a: 0x1020, b: 0x30FF, vm: vm, memory: &memory)
        checkMul(reg1: vm.register0, reg2: vm.register1, a: 0x10FF, b: 0x3070, vm: vm, memory: &memory)
        checkMul(reg1: vm.register0, reg2: vm.register1, a: 0xFF20, b: 0x3070, vm: vm, memory: &memory)
        checkMul(reg1: vm.register0, reg2: vm.register1, a: 0xFFFF, b: 0x0001, vm: vm, memory: &memory)
        checkMul(reg1: vm.register0, reg2: vm.register1, a: 0xFFFF, b: 0xFF00, vm: vm, memory: &memory)
    }
    
    private func checkMul(reg1: BigRegister16, a: UInt16, b: UInt8, inline: Bool, memory: inout [UInt8]) {
        memory.setRegister16Value(reg1, value: a)
        
        brainfuckInterpreter(&memory) {
            reg1.mul(b, inline: inline)
        }
        
        let value = (Int(a) * Int(b)) % (0xFFFF + 1)
        XCTAssert(memory.checkRegister16Value(reg1, value: UInt16(value)))
    }
    
    private func checkMul(
        reg1: BigRegister16,
        reg2: BigRegister16,
        a: UInt16,
        b: UInt16,
        vm: VirtualMachine,
        memory: inout [UInt8]
    ) {
        memory.setRegister16Value(reg1, value: a)
        memory.setRegister16Value(reg2, value: b)
        
        brainfuckInterpreter(&memory) {
            reg1.mul(reg2, vm: vm)
        }
        
        XCTAssert(memory.checkRegister16Value(reg1, value: UInt16((Int(a) * Int(b)) % (0xFFFF + 1))))
        XCTAssert(memory.checkRegister16Value(reg2, value: b))
    }
}
