struct Right3ByteFastZeroIfCell: IRight3ByteFastZeroIfCell, IValueIndex {
    let value: Int
    
    let zero0: Int
    let one0: Int
    
    let index: Int
    
    init(firstByte: Int) {
        self.index = firstByte + 2
        
        self.value = firstByte + 2
        self.zero0 = firstByte + 1
        self.one0 = firstByte
    }
}

protocol IRight3ByteFastZeroIfCell: I3ByteCell {
    var index: Int { get }
}

extension IRight3ByteFastZeroIfCell {
    func ifNotZero(
        requiredInit: Bool = false,
        @MacrosBuilder _ notZero: () -> IMacros
    ) -> IMacros {
        let notZero = notZero()

        // 1 0 v
        return body {
            ActiveCell(index) {
                UnsafeMacros {
                    if requiredInit {
                        init3Memory()
                    }
                    "["
                        notZero
                        SetCell(index)
                    "<]<[>]>"
                }
            }

        }
    }
}

