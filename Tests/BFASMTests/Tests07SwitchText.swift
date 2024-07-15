import XCTest
@testable import BFASM
    
class Tests07SwitchText: XCTestCase {
    func test01Read() {
        var memory: [UInt8] = .init(repeating: 0, count: 256 * 256)
        let vm = VirtualMachine()
        var outputs: [String] = []
        brainfuckInterpreter(input: "NO_OK OK NO_OK    OZ  hfdh OKNO_OK END", &memory) {
            vm.initMemory()
            Set(index: vm.tmp1.lowCell.zero0, 1)
            SafeLoop(index: vm.tmp1.lowCell.zero0) {
                ReadStringSwitch(vm: vm) {
                    StringSwitchCase("OK") {
                        CustomBreakPoint { memory, currentPoint in
                            outputs.append("OK")
                        }
                    }
                    StringSwitchCase("NO_OK") {
                        CustomBreakPoint { memory, currentPoint in
                            outputs.append("NO_OK")
                        }
                    }
                    StringSwitchCase("OZ") {
                        CustomBreakPoint { memory, currentPoint in
                            outputs.append("OZ")
                        }
                    }
                    StringSwitchCase("END") {
                        Set(index: vm.tmp1.lowCell.zero0, 0)
                        CustomBreakPoint { memory, currentPoint in
                            outputs.append("END")
                        }
                    }
                    StringSwitchCase {
                        CustomBreakPoint { memory, currentPoint in
                            outputs.append("0")
                        }
                    }
                }
            }
        }
        let result = ["NO_OK", "OK", "NO_OK", "OZ", "0", "0", "0", "0", "OK", "NO_OK", "END"]
        XCTAssert(result == outputs)
    }
}

