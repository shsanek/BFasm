struct ActiveCell: IMacros {
    private let value: Int
    private let content: IMacros

    init(
        _ value: Int,
        @MacrosBuilder content: () -> IMacros
    ) {
        self.value = value
        self.content = content()
    }

    func generateCode(manager: SelectedCellManager) -> String {
        let saveIndex = manager.selectCell
        return body {
            SetCell(value)
            content
            SetCell(saveIndex)
        }.generateCode(manager: manager)
    }

    func checkShift(manager: SelectedCellManager) -> Int? {
        return 0
    }
}
