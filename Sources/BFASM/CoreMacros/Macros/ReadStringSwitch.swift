import Foundation

struct ReadStringSwitch: IMacros {
    let elements: [StringSwitchCase]

    let vm: VirtualMachine

    init(
        vm: VirtualMachine,
        _ elements: [StringSwitchCase],
        @MacrosBuilder _ defaultCase: () -> IMacros = { emptyBody }
    ) {
        assert(!elements.filter({ $0.string != nil }).isEmpty)
        self.elements = elements + [.init(defaultCase)]
        self.vm = vm
    }
    
    init(
        vm: VirtualMachine,
        @StringSwitchBuilder _ elements: () -> [StringSwitchCase]
    ) {
        self.elements = elements()
        assert(!self.elements.filter({ $0.string != nil }).isEmpty)
        self.vm = vm
    }

    func generateCode(manager: SelectedCellManager) -> String {
        body {
            ReadAllSymbols(vm: vm, reg: vm.tmp0)
            generateForPrefix("")
            SafeLoop(index: vm.tmp0.highCell.zero1) {
                vm.input.setNeedNextRead()
                SequenceMacros(macros: elements.filter({ $0.string == nil }).map({ $0.action }))
                Set(index: vm.tmp0.highCell.zero1, 0)
            }
        }.generateCode(manager: manager)
    }
    
    private func generateForPrefix(_ prefix: String) -> IMacros {
        var elements = [(key: String, action: IMacros)]()
        self.elements.forEach { element in
            if let key = element.string, element.string?.hasPrefix(prefix) == true {
                elements.append((key: key, action: element.action))
            }
        }
        var switchCases: [SwitchCase] = []
        if elements[0].key == prefix {
            if elements.count == 1 {
                return body {
                    vm.input.setNeedNextRead()
                    elements[0].action
                }
            }
            assert(false)
        } else {
            let nextSymbols = elements.map({
                assert($0.key != prefix)
                return "\($0.key.prefix(prefix.count + 1).dropFirst(prefix.count))"
            })
            let nextSymbolsSet = Swift.Set(nextSymbols)
            switchCases = nextSymbolsSet.map { nextSymbol in
                return SwitchCase(nextSymbol) {
                    vm.input.setNeedNextRead()
                    generateForPrefix(prefix + nextSymbol)
                }
            }
        }
        return body {
            vm.input.readIfNeededTo(vm.tmp0.highCell)
            Switch(cell: vm.tmp0.highCell, switchCases) {
                Set(index: vm.tmp0.highCell.zero1, 1)
            }
        }
    }
        
    func checkShift(manager: SelectedCellManager) -> Int? {
        return 0
    }
}

struct StringSwitchCase {
    let string: String?
    let action: IMacros
    
    init(@MacrosBuilder _ action: () -> IMacros) {
        self.string = nil
        self.action = action()
    }
    
    init(_ string: String, @MacrosBuilder _ action: () -> IMacros) {
        self.string = string
        self.action = action()
    }
}

@resultBuilder
struct StringSwitchBuilder {
    static func buildBlock(_ components: StringSwitchCase...) -> [StringSwitchCase] {
        return components
    }
}

