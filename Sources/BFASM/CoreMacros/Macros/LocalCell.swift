struct LocalCell: IMacros {
    private let shift: Int?
    private let content: IMacros

    init(@MacrosBuilder _ content: () -> IMacros) {
        self.content = content()
        self.shift = self.content.checkShift(manager: SelectedCellManager(activeBreakPoints: .init()))
    }

    func generateCode(manager: SelectedCellManager) -> String {
        body {
            content
            SetCell(0)
        }.generateCode(manager: SelectedCellManager(activeBreakPoints: manager.activeBreakPoints))
    }

    func checkShift(manager: SelectedCellManager) -> Int? {
        return shift
    }
}
