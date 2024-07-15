struct ConstLoop: IMacros {
    private let content: IMacros
    private let count: Int

    init(count: Int, @MacrosBuilder _ content: () -> IMacros) {
        self.content = SequenceMacros(macros: (0..<count).map({ _ in content() }))
        self.count = count
    }
    
    init(count: Int, _ content: (Int) -> IMacros) {
        self.content = SequenceMacros(macros: (0..<count).map({ index in content(index) }))
        self.count = count
    }

    func generateCode(manager: SelectedCellManager) -> String {
        content.generateCode(manager: manager)
    }

    func checkShift(manager: SelectedCellManager) -> Int? {
        return 0
    }
}
