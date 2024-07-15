struct UnsafeMacros: IMacros  {
    private let macro: IMacros
    
    init(@MacrosBuilder _ content: () -> IMacros) {
        self.macro = content()
    }
    
    func generateCode(manager: SelectedCellManager) -> String {
        macro.generateCode(manager: manager)
    }
    
    func checkShift(manager: SelectedCellManager) -> Int? {
        return 0
    }
}
