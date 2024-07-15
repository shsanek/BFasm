struct Left4ByteFastZeroIfCell: IValueIndex, ILeft3ByteFastZeroIfCell, I4ByteCell {
    let index: Int
    
    let value: Int
    
    let zero0: Int
    let zero1: Int
    let one0: Int
    
    // 0 v 0 1
    init(firstByte: Int) {
        self.index = firstByte + 1
        
        self.value = firstByte + 1
        self.zero0 = firstByte + 2
        self.zero1 = firstByte
        self.one0 = firstByte + 3
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

        // 0 v 0 1
        return body {
            ActiveCell(index) {
                UnsafeMacros {
                    if requiredInit {
                        initMemory()
                    }
                    "["
                        notZero
                        SetCell(index)
                    "<]>>["
                        "<<"
                        zero
                        SetCell(index)
                        ">"
                    "]<"
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
