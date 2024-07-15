extension String: IMacros {
    func generateCode(manager: SelectedCellManager) -> String {
        return self
    }

    func checkShift(manager: SelectedCellManager) -> Int? {
        if contains("[") || contains("]") {
            return nil
        }
        return reduce(0, {
            if $1 == ">" {
                return $0 + 1
            } else if $1 == "<" {
                return $0 - 1
            }
            return $0
        })
    }
}
