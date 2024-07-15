import XCTest
@testable import BFASM
    
class Tests11Sub: XCTestCase {
    func test01BaseSub() {
        var memory: [UInt8] = .init(repeating: 0, count: 256 * 256)
        let vm = VirtualMachine()
        brainfuckInterpreter(&memory) {
            vm.initMemory()
        }
        
        checkSub(reg1: vm.register0, reg2: vm.register1, a: 0x0000, b: 0x0000, memory: &memory)
        checkSub(reg1: vm.register0, reg2: vm.register1, a: 0x0001, b: 0x0000, memory: &memory)
        checkSub(reg1: vm.register0, reg2: vm.register1, a: 0x0100, b: 0x0000, memory: &memory)
        checkSub(reg1: vm.register0, reg2: vm.register1, a: 0x0000, b: 0x0001, memory: &memory)
        checkSub(reg1: vm.register0, reg2: vm.register1, a: 0x0000, b: 0x0010, memory: &memory)
        checkSub(reg1: vm.register0, reg2: vm.register1, a: 0x1020, b: 0x3070, memory: &memory)
        checkSub(reg1: vm.register0, reg2: vm.register1, a: 0x1020, b: 0x30FF, memory: &memory)
        checkSub(reg1: vm.register0, reg2: vm.register1, a: 0x10FF, b: 0x3070, memory: &memory)
        checkSub(reg1: vm.register0, reg2: vm.register1, a: 0xFF20, b: 0x3070, memory: &memory)
        checkSub(reg1: vm.register0, reg2: vm.register1, a: 0xFFFF, b: 0x0001, memory: &memory)
    }

    func test02ConstSub() {
        var memory: [UInt8] = .init(repeating: 0, count: 256 * 256)
        let vm = VirtualMachine()
        brainfuckInterpreter(&memory) {
            vm.initMemory()
        }
        
        checkSub(reg1: vm.register0, a: 0x0000, b: 0x0000, memory: &memory)
        checkSub(reg1: vm.register0, a: 0x0001, b: 0x0000, memory: &memory)
        checkSub(reg1: vm.register0, a: 0x0100, b: 0x0000, memory: &memory)
        checkSub(reg1: vm.register0, a: 0x0000, b: 0x0001, memory: &memory)
        checkSub(reg1: vm.register0, a: 0x0000, b: 0x0010, memory: &memory)
        checkSub(reg1: vm.register0, a: 0x1020, b: 0x0070, memory: &memory)
        checkSub(reg1: vm.register0, a: 0x1020, b: 0x00FF, memory: &memory)
        checkSub(reg1: vm.register0, a: 0x10FF, b: 0x0070, memory: &memory)
        checkSub(reg1: vm.register0, a: 0xFF20, b: 0x0070, memory: &memory)
        checkSub(reg1: vm.register0, a: 0xFFFF, b: 0x0001, memory: &memory)
        checkSub(reg1: vm.register0, a: 370, b: 3, memory: &memory)
    }
    
    func test03cmp() {
        var memory: [UInt8] = .init(repeating: 0, count: 256 * 256)
        let vm = VirtualMachine()
        brainfuckInterpreter(&memory) {
            vm.initMemory()
        }
        
        checkCMP(reg1: vm.register0, reg2: vm.register1, a: 0x0000, b: 32768, vm: vm, memory: &memory)
        checkCMP(reg1: vm.register0, reg2: vm.register1, a: 0x0000, b: 0x0000, vm: vm, memory: &memory)
        checkCMP(reg1: vm.register0, reg2: vm.register1, a: 0x0001, b: 0x0000, vm: vm, memory: &memory)
        checkCMP(reg1: vm.register0, reg2: vm.register1, a: 0x0100, b: 0x0000, vm: vm, memory: &memory)
        checkCMP(reg1: vm.register0, reg2: vm.register1, a: 0x0000, b: 0x0001, vm: vm, memory: &memory)
        checkCMP(reg1: vm.register0, reg2: vm.register1, a: 0x0000, b: 0x0010, vm: vm, memory: &memory)
        checkCMP(reg1: vm.register0, reg2: vm.register1, a: 0x1020, b: 0x3070, vm: vm, memory: &memory)
        checkCMP(reg1: vm.register0, reg2: vm.register1, a: 0x1020, b: 0x30FF, vm: vm, memory: &memory)
        checkCMP(reg1: vm.register0, reg2: vm.register1, a: 0x10FF, b: 0x3070, vm: vm, memory: &memory)
        checkCMP(reg1: vm.register0, reg2: vm.register1, a: 0x00FF, b: 0xFFFF, vm: vm, memory: &memory)
        checkCMP(reg1: vm.register0, reg2: vm.register1, a: 0x1010, b: 0x1010, vm: vm, memory: &memory)
        checkCMP(reg1: vm.register0, reg2: vm.register1, a: 0x0010, b: 0x0010, vm: vm, memory: &memory)
        checkCMP(reg1: vm.register0, reg2: vm.register1, a: 0x0110, b: 0x0111, vm: vm, memory: &memory)
        checkCMP(reg1: vm.register0, reg2: vm.register1, a: 0xFFFF, b: 0x0001, vm: vm, memory: &memory)
    }
    
    private func checkCMP(reg1: BigRegister16, reg2: BigRegister16, a: UInt16, b: UInt16, vm: VirtualMachine, memory: inout [UInt8]) {
        memory.setRegister16Value(reg1, value: a)
        memory.setRegister16Value(reg2, value: b)
        
        var result: Int = 0
        
        brainfuckInterpreter(&memory) {
            reg1.cmp(reg2, saveOperand: true, vm: vm)
            vm.flags.ifOver {
                CustomBreakPoint { _, _ in
                    result = -1
                }
            } else: {
                CustomBreakPoint { _, _ in
                    result = 1
                }
            }
            vm.flags.ifZero {
                CustomBreakPoint { _, _ in
                    assert(result == 1)
                    result = 0
                }
            } else: {
                CustomBreakPoint { _, _ in
                }
            }
        }
        if b > a {
            XCTAssert(result < 0)
        } else if b < a {
            XCTAssert(result > 0)
        } else {
            XCTAssert(result == 0)
        }
        XCTAssert(memory.checkRegister16Value(reg1, value: a))
        XCTAssert(memory.checkRegister16Value(reg2, value: b))
    }
    
    private func checkSub(reg1: BigRegister16, a: UInt16, b: UInt8, memory: inout [UInt8]) {
        memory.setRegister16Value(reg1, value: a)
        
        brainfuckInterpreter(&memory) {
            reg1.subConst(b)
        }
        
        let value = (Int(a) - Int(b) + (0xFFFF + 1)) % (0xFFFF + 1)
        XCTAssert(memory.checkRegister16Value(reg1, value: UInt16(value)))
    }
    
    private func checkSub(reg1: BigRegister16, reg2: BigRegister16, a: UInt16, b: UInt16, memory: inout [UInt8]) {
        memory.setRegister16Value(reg1, value: a)
        memory.setRegister16Value(reg2, value: b)
        
        brainfuckInterpreter(&memory) {
            reg1.sub(reg2)
        }
        
        let value = (Int(a) - Int(b) + (0xFFFF + 1)) % (0xFFFF + 1)

        XCTAssert(memory.checkRegister16Value(reg1, value: UInt16(value)))
        XCTAssert(memory.checkRegister16Value(reg2, value: b))
    }
}

