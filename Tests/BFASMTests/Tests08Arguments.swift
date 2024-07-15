import XCTest
@testable import BFASM
    
class Tests08Arguments: XCTestCase {
    func test01Read() {
        var memory: [UInt8] = .init(repeating: 0, count: 256 * 256)
        let vm = VirtualMachine()
        brainfuckInterpreter(input: "; ptr r0 r1; r1 r2; r2 ptr r0; ptr r2 373; r2 736; 76; r0;", &memory) {
            vm.initMemory()
            ConstLoop(count: 8) {
                vm.command.set(0)
                CommandArgumentReader(vm: vm) {
                    CustomBreakPoint { memory, currentPoint in
                        print("error")
                    }
                }
            }
        }
        let dump = memory.dump(vm).map({ Int($0) })
        let result = [28, 21, 15, 10, 20, 373, 5, 736, 27, 76, 0]
        XCTAssert(Array(dump.prefix(result.count)) == result)
    }
    
    func test02Read() {
        var memory: [UInt8] = .init(repeating: 0, count: 256 * 256)
        let vm = VirtualMachine()
        brainfuckInterpreter(input: "; ptr r0 r1; r1 r2; r2 ptr r0; ptr r2 373; r2 736; 76; r0;", &memory) {
            vm.initMemory()
            ConstLoop(count: 8) {
                vm.command.set(0)
                Command2ArgumentReader(vm: vm) {
                    CustomBreakPoint { memory, currentPoint in
                        assert(false)
                    }
                }.parseArgument()
            }
        }
        let dump = memory.dump(vm).map({ Int($0) })
        
        let result = [
            command2ArgumentsCombination(.none, .none),
            command2ArgumentsCombination(.ptrRegister0, .register1),
            command2ArgumentsCombination(.register1, .register2),
            command2ArgumentsCombination(.register2, .ptrRegister0),
            command2ArgumentsCombination(.ptrRegister2, .const), 373,
            command2ArgumentsCombination(.register2, .const), 736,
            command2ArgumentsCombination(.const, .none), 76,
            command2ArgumentsCombination(.register0, .none)
        ]
        XCTAssert(Array(dump.prefix(result.count)) == result)
    }
}
