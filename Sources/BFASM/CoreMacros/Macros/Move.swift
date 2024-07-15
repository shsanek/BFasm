struct Move: IMacros {
    let value: Int

    init(_ value: Int) {
        self.value = value
    }

    func generateCode(manager: SelectedCellManager) -> String {
        if (value > 0) {
            manager.selectCell += value
            return Array(repeating: ">", count: value).joined()
        }
        if (value < 0) {
            manager.selectCell += value
            return Array(repeating: "<", count: -value).joined()
        }
        return ""
    }

    func checkShift(manager: SelectedCellManager) -> Int? {
        manager.selectCell += value
        return value
    }
}

struct UnsafeMove: IMacros {
    let value: Int

    init(_ value: Int) {
        self.value = value
    }

    func generateCode(manager: SelectedCellManager) -> String {
        if (value > 0) {
            return Array(repeating: ">", count: value).joined()
        }
        if (value < 0) {
            return Array(repeating: "<", count: -value).joined()
        }
        return ""
    }

    func checkShift(manager: SelectedCellManager) -> Int? {
        return 0
    }
}


