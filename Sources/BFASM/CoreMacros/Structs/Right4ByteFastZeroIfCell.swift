struct Right4ByteFastZeroIfCell: IRight3ByteFastZeroIfCell, IValueIndex, I4ByteCell {
    
    let value: Int
    
    let zero0: Int
    let zero1: Int
    let one0: Int
    
    let index: Int
    
    init(firstByte: Int) {
        self.index = firstByte + 2

        self.value = firstByte + 2

        self.zero1 = firstByte + 3
        self.zero0 = firstByte + 1
        self.one0 = firstByte
    }
    
    func initMemory() -> IMacros {
        init4Memory()
    }

    func `if`(
        requiredInit: Bool = false,
        @MacrosBuilder notZero: () -> IMacros,
        @MacrosBuilder zero: () -> IMacros
    ) -> IMacros {
        let notZero = notZero()
        let zero = zero()

        // 1 0 v 0
        return body {
            ActiveCell(index) {
                UnsafeMacros {
                    if requiredInit {
                        initMemory()
                    }
                    "["
                        notZero
                        SetCell(index)
                    ">]<<["
                    ">>"
                        zero
                        SetCell(index)
                    "<"
                    "]>"
                }
            }
        }
    }
    
    func ifZero(
        requiredInit: Bool = false,
        @MacrosBuilder _ zero: () -> IMacros
    ) -> IMacros {
        self.if(notZero: { emptyBody }, zero: zero)
    }
}
