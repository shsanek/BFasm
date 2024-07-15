import XCTest
@testable import BFASM
    
class Tests06Read: XCTestCase {
    func test01Read() {
        var memory: [UInt8] = .init(repeating: 0, count: 256 * 256)
        let vm = VirtualMachine()
        brainfuckInterpreter(&memory) {
            vm.initMemory()
        }
        
        brainfuckInterpreter(input: "0 ", &memory) {
            ReadInt16(vm: vm, reg: vm.register0)
        }
        XCTAssert(memory.checkRegister16Value(vm.register0, value: 0))
        
        brainfuckInterpreter(input: "  \t  10 ", &memory) {
            ReadInt16(vm: vm, reg: vm.register0)
        }
        XCTAssert(memory.checkRegister16Value(vm.register0, value: 10))

        brainfuckInterpreter(input: "12312 ", &memory) {
            ReadInt16(vm: vm, reg: vm.register0)
        }
        XCTAssert(memory.checkRegister16Value(vm.register0, value: 12312))
        
        brainfuckInterpreter(input: "\t 0", &memory) {
            ReadInt16(vm: vm, reg: vm.register0)
        }
        XCTAssert(memory.checkRegister16Value(vm.register0, value: 0))
    }
}
