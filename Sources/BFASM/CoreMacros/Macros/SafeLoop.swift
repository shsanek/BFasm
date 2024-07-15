struct SafeLoop: IMacros {
    private let content: IMacros
    private let index: Int

    init(index: Int, @MacrosBuilder _ content: () -> IMacros) {
        self.content = content()
        self.index = index
    }

    func generateCode(manager: SelectedCellManager) -> String {
        return body {
            SetCell(index)
            "["
                content
                SetCell(index)
            "]"
        }.generateCode(manager: manager)
    }

    func checkShift(manager: SelectedCellManager) -> Int? {
        return 0
    }
}

func FastIf(index: Int, @MacrosBuilder _ content: () -> IMacros) -> IMacros {
    body {
        SafeLoop(index: index) {
            content()
            Set(index: index, 0)
        }
    }
}
