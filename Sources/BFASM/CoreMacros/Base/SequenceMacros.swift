struct SequenceMacros: IMacros {
    private let macros: [IMacros]
    
    init(macros: [IMacros]) {
        self.macros = macros
    }

    func generateCode(manager: SelectedCellManager) -> String {
        macros.map({ $0.generateCode(manager: manager) }).joined()
    }

    func checkShift(manager: SelectedCellManager) -> Int? {
        var shift = 0
        for macro in macros {
            if let value = macro.checkShift(manager: manager) {
                shift += value
            } else {
                return nil
            }
        }
        return shift
    }
}
