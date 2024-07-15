struct RegisterFlags {
    static let size: Int = 7
    
    let index: Int
    let runFlag: Int
    let errorFlag: Int
    let overFlag: Int
    let inverOverFlag: Int
    let inverZeroFlag: Int
    let zeroFlag: Int
    
    init(firstByte: Int) {
        index = firstByte
        runFlag = firstByte
        errorFlag = firstByte + 1
    
        overFlag = firstByte + 2
        inverOverFlag = firstByte + 3
    
        zeroFlag = firstByte + 4
        inverZeroFlag = firstByte + 5
    }
    
    func resetOverFlag() -> IMacros {
        body {
            Set(index: overFlag, 0)
            Set(index: zeroFlag, 0)
        }
    }
    
    func setOverFlag() -> IMacros {
        body {
            Set(index: overFlag, 1)
        }
    }
    
    func setZeroFlag() -> IMacros {
        body {
            Set(index: zeroFlag, 1)
        }
    }
    
    private func ifGeneric(
        index: Int,
        save: Bool = true,
        @MacrosBuilder _ trueAction: () -> IMacros  = { emptyBody },
        @MacrosBuilder `else`: () -> IMacros = { emptyBody }
    ) -> IMacros {
        body {
            Set(index: index + 1, 1)
            FastIf(index: index) {
                trueAction()
                Set(index: index + 1, 0)
            }

            Set(index: index, 1)
            FastIf(index: index + 1) {
                `else`()
                if save {
                    Set(index: index, 0)
                }
            }
        }
    }
    
    func ifOver(save: Bool = true, @MacrosBuilder _ trueAction: () -> IMacros, @MacrosBuilder `else`: () -> IMacros) -> IMacros {
        body {
            ifGeneric(index: overFlag, save: save, trueAction, else: `else`)
        }
    }
    
    func ifZero(save: Bool = true, @MacrosBuilder _ trueAction: () -> IMacros, @MacrosBuilder `else`: () -> IMacros = { emptyBody }) -> IMacros {
        body {
            ifGeneric(index: zeroFlag, save: save, trueAction, else: `else`)
        }
    }
}
