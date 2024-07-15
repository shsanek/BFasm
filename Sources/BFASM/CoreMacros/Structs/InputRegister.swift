final class InputRegister {
    static let size: Int = 5

    let index: Int
    let value: Left4ByteFastZeroIfCell
    let needReadFlag: Int
    
    init(firstByte: Int) {
        self.index = firstByte
        self.value = .init(firstByte: firstByte)
        self.needReadFlag = firstByte + 4
    }
    
    func initMemory() -> IMacros {
        body {
            value.initMemory()
            Set(index: needReadFlag, 1)
        }
    }
    
    func setNeedNextRead() -> IMacros {
        Set(index: needReadFlag, 1)
    }
    
    func resetNeedNextRead() -> IMacros {
        Set(index: needReadFlag, 0)
    }

    func forceRead() -> IMacros {
        body {
            SetCell(value.value) 
            ",."
            SetZero(needReadFlag)
        }
    }
    
    func readAndSetNextRead(_ cell: I3ByteCell) -> IMacros {
        body {
            readIfNeededTo(cell)
            setNeedNextRead()
        }
    }
    
    func readIfNeeded() -> IMacros {
        body {
            SafeLoop(index: needReadFlag) {
                forceRead()
            }
        }
    }
    
    func readIfNeededTo(_ cell: I3ByteCell) -> IMacros {
        body {
            readIfNeeded()
            value.copy(to: cell)
        }
    }
}
