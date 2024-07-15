import XCTest
@testable import BFASM
    
class Tests11Div: XCTestCase {
    
    func test01ConstDiv() {
        var memory: [UInt8] = .init(repeating: 0, count: 256 * 256)
        let vm = VirtualMachine()
        brainfuckInterpreter(&memory) {
            vm.initMemory()
        }
        
        checkDiv(vm: vm, a: 0x0000, b: 0x0001, memory: &memory)
        checkDiv(vm: vm, a: 0x0000, b: 0x0010, memory: &memory)
        checkDiv(vm: vm, a: 0x1020, b: 0x0070, memory: &memory)
        checkDiv(vm: vm, a: 0x1020, b: 0x00FF, memory: &memory)
        checkDiv(vm: vm, a: 0x10FF, b: 0x0070, memory: &memory)
        checkDiv(vm: vm, a: 0xFF20, b: 0x0070, memory: &memory)
        checkDiv(vm: vm, a: 0xFFFF, b: 0x0001, memory: &memory)
        checkDiv(vm: vm, a: 370, b: 3, memory: &memory)
    }
    
    func test02Div() {
        var memory: [UInt8] = .init(repeating: 0, count: 256 * 256)
        let vm = VirtualMachine()
        brainfuckInterpreter(&memory) {
            vm.initMemory()
        }
        
        checkBigDiv(vm: vm, a: 0x0000, b: 0x0001, memory: &memory)
        checkBigDiv(vm: vm, a: 0x0000, b: 0x0010, memory: &memory)
        checkBigDiv(vm: vm, a: 0x1020, b: 0x0170, memory: &memory)
        checkBigDiv(vm: vm, a: 0x0008, b: 0x0002, memory: &memory)
        checkBigDiv(vm: vm, a: 0x1020, b: 0x00FF, memory: &memory)
        checkBigDiv(vm: vm, a: 0x10FF, b: 0x0270, memory: &memory)
        checkBigDiv(vm: vm, a: 0xFF20, b: 0x1070, memory: &memory)
        checkBigDiv(vm: vm, a: 0xFFFF, b: 0x0001, memory: &memory)
        checkBigDiv(vm: vm, a: 0xFFFF, b: 0x0002, memory: &memory)
        checkBigDiv(vm: vm, a: 0xFFFF, b: 0x0101, memory: &memory)
        checkBigDiv(vm: vm, a: 0xFFFF, b: 0xFFFF, memory: &memory)
        checkBigDiv(vm: vm, a: 255, b: 1, memory: &memory)

        checkBigDiv(vm: vm, a: 370, b: 3, memory: &memory)
    }
    
    private func checkDiv(vm: VirtualMachine, a: UInt16, b: UInt8, memory: inout [UInt8]) {
        memory.setRegister16Value(vm.register0, value: a)
        
        brainfuckInterpreter(&memory) {
            vm.register0.divConst(b, result: vm.register0, mod: vm.register1, vm: vm)
        }
        
        let value = ((Int(a) / Int(b))) % (0xFFFF + 1)
        let mod = ((Int(a) % Int(b))) % (0xFFFF + 1)
        XCTAssert(memory.checkRegister16Value(vm.register0, value: UInt16(value)))
        XCTAssert(memory.checkRegister16Value(vm.register1, value: UInt16(mod)))
    }
    
    private func checkBigDiv(vm: VirtualMachine, a: UInt16, b: UInt16, memory: inout [UInt8]) {
        memory.setRegister16Value(vm.destination, value: a)
        memory.setRegister16Value(vm.operand, value: b)

        brainfuckInterpreter(&memory) {
            vm.destination.div(
                operand: vm.operand,
                result: vm.destination,
                mod: vm.tmp0,
                vm: vm
            )
        }
        
        let value = ((Int(a) / Int(b))) % (0xFFFF + 1)
        let mod = ((Int(a) % Int(b))) % (0xFFFF + 1)
        XCTAssert(memory.checkRegister16Value(vm.destination, value: UInt16(value)))
        XCTAssert(memory.checkRegister16Value(vm.operand, value: b))
        XCTAssert(memory.checkRegister16Value(vm.tmp0, value: UInt16(mod)))
    }
}


