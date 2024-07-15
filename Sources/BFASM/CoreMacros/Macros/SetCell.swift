struct SetCell: IMacros {
    private let value: Int

    init(_ value: Int) {
        self.value = value
    }

    func generateCode(manager: SelectedCellManager) -> String {
        let shift = value - manager.selectCell
        return Move(shift).generateCode(manager: manager)
    }

    func checkShift(manager: SelectedCellManager) -> Int? {
        let shift = value - manager.selectCell
        return Move(shift).checkShift(manager: manager)
    }
}
