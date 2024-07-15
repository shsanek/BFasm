import XCTest
@testable import BFASM
    
class Tests03Switch: XCTestCase {
    func test01BaseSwitch() {
        var memory: [UInt8] = .init(repeating: 0, count: 256 * 256 * 256)
        let vm = VirtualMachine()
        
        for active in 0...1 {
            genericSwitchTest(
                values: (0...255).map { $0 },
                activeDefault: active == 1 ? true : false,
                cell: vm.register0.lowCell,
                memory: &memory
            )
            
            genericSwitchTest(
                values: (0...10).map { $0 },
                activeDefault: active == 1 ? true : false,
                cell: vm.register0.lowCell,
                memory: &memory
            )
            
            genericSwitchTest(
                values: (245...255).map { $0 },
                activeDefault: active == 1 ? true : false,
                cell: vm.register0.lowCell,
                memory: &memory
            )
            
            genericSwitchTest(
                values: (50...60).map { $0 },
                activeDefault: active == 1 ? true : false,
                cell: vm.register0.lowCell,
                memory: &memory
            )
            
            genericSwitchTest(
                values: (0...0).map { $0 },
                activeDefault: active == 1 ? true : false,
                cell: vm.register0.lowCell,
                memory: &memory
            )
            
            genericSwitchTest(
                values: (255...255).map { $0 },
                activeDefault: active == 1 ? true : false,
                cell: vm.register0.lowCell,
                memory: &memory
            )
            
            genericSwitchTest(
                values: (10...10).map { $0 },
                activeDefault: active == 1 ? true : false,
                cell: vm.register0.lowCell,
                memory: &memory
            )
        }
    }
    
    func genericSwitchTest(values: [UInt8], activeDefault: Bool, cell: I3ByteCell, memory: inout [UInt8]) {
        var resultValues = [UInt8?]()
        var elements = values.map { value in
            SwitchCase(value, {
                CustomBreakPoint { memory, currentPoint in
                    resultValues.append(value)
                }
            })
        }
        if activeDefault {
            elements.append(SwitchCase({
                CustomBreakPoint { memory, currentPoint in
                    resultValues.append(nil)
                }
            }))
        }
        var fullVariation: Set<Int> = Set<Int>(values.map({ Int($0) }))
        fullVariation.insert(values.min().flatMap({ Int($0) - 1 }) ?? 0)
        fullVariation.insert(values.max().flatMap({ Int($0) - 1 }) ?? 255)
        fullVariation.insert(values.max().flatMap({ Int($0) - 1 }) ?? 255)
        fullVariation.insert(0)
        fullVariation.insert(255)
        fullVariation = fullVariation.filter({ $0 >= 0 && $0 <= 255 })

        for i in fullVariation {
            let code = UInt8(i)
            resultValues = []
            brainfuckInterpreter(&memory) {
                Set(index: cell.value, Int(code))
                Switch(cell: cell, elements)
                CustomBreakPoint { memory, currentPoint in
                    if values.contains(code) {
                        assert(resultValues.count == 1 && resultValues[0] == code)
                    } else if activeDefault {
                        assert(resultValues.count == 1 && resultValues[0] == nil)
                    } else {
                        assert(resultValues.count == 0)
                    }
                }
            }
        }
    }
}

