struct Switch: IMacros {
    let cell: I3ByteCell
    let elements: [SwitchCase]

    let activeDefault: Int
    let needActiveAction: Int

    init(cell: I3ByteCell, _ elements: [SwitchCase], @MacrosBuilder _ defaultCase: () -> IMacros = { emptyBody }) {
        self.cell = cell
        self.elements = elements + [.init(defaultCase)]
        self.activeDefault = cell.zero0
        self.needActiveAction = cell.one0
    }
    
    init(cell: I3ByteCell, @SwitchBuilder _ elements: () -> [SwitchCase]) {
        self.cell = cell
        self.elements = elements()
        self.activeDefault = cell.zero0
        self.needActiveAction = cell.one0
    }

    func generateCode(manager: SelectedCellManager) -> String {
        var cases = [UInt8: IMacros]()
        var defaults = [IMacros]()
                
        elements.forEach { caseElement in
            if let code = caseElement.code {
                cases[code] = caseElement.action
            } else {
                defaults.append(caseElement.action)
            }
        }
        let defaultAction = SequenceMacros(macros: defaults)
        guard let minCode = cases.keys.min(), let maxCode = cases.keys.max() else {
            return defaultAction.generateCode(manager: manager)
        }

        return body {
            Set(index: needActiveAction, 1)
            Set(index: activeDefault, 1)
            Add(index: cell.value, -Int(minCode))
            generateCase(cases: cases, current: Int(minCode), max: Int(maxCode) + 1)
            SafeLoop(index: activeDefault) {
                defaultAction
                SetZero(activeDefault)
            }
            cell.init3Memory()
        }.generateCode(manager: manager)
    }
    
    private func generateCase(cases: [UInt8: IMacros], current: Int, max: Int) -> IMacros {
        if current == max {
            return body {
                Set(index: needActiveAction, 0)
                SetZero(cell.value)
            }
        }
        let code = UInt8(current % 256)
        let action = cases[code].flatMap { action in
            body {
                action
                Set(index: activeDefault, 0)
            }
        } ?? emptyBody
        return body {
            SafeLoop(index: cell.value) {
                Add(index: cell.value, -1)
                generateCase(cases: cases, current: current + 1, max: max)
            }
            SafeLoop(index: needActiveAction) {
                action
                Set(index: cell.value, 0)
                Set(index: needActiveAction, 0)
            }
        }
    }
        
    func checkShift(manager: SelectedCellManager) -> Int? {
        return 0
    }
}

struct SwitchCase {
    let code: UInt8?
    let action: IMacros
    
    init(@MacrosBuilder _ action: () -> IMacros) {
        self.code = nil
        self.action = action()
    }
    
    init(_ code: UInt8, @MacrosBuilder _ action: () -> IMacros) {
        self.code = code
        self.action = action()
    }
    
    init(_ char: String, @MacrosBuilder _ action: () -> IMacros) {
        assert(char.count == 1)
        self.code = char.first!.asciiValue!
        self.action = action()
    }
}

@resultBuilder
struct SwitchBuilder {
    static func buildBlock(_ components: SwitchCase...) -> [SwitchCase] {
        return components
    }
}
