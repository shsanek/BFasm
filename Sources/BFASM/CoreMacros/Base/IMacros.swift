class SelectedCellManager {
    let activeBreakPoints: BreakPointPool
    var selectCell: Int = 0
    
    init(activeBreakPoints: BreakPointPool, selectCell: Int = 0) {
        self.activeBreakPoints = activeBreakPoints
        self.selectCell = selectCell
    }
}

protocol IMacros {
    func generateCode(manager: SelectedCellManager) -> String
    func checkShift(manager: SelectedCellManager) -> Int?
}

