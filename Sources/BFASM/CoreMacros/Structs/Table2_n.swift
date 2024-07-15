struct Table2_n {
    let index: Int
    static let size: Int = 4 * 2 + 1 + BigRegister16.size
    private let value: BigRegister16
    private let tmpValue: Left4ByteFastZeroIfCell
    private let currentNumber: Left4ByteFastZeroIfCell
    private let loop: Int
    
    init(firstByte: Int) {
        index = firstByte
        value = .init(firstByte: firstByte)
        tmpValue = .init(firstByte:  BigRegister16.size + firstByte)
        currentNumber = .init(firstByte: BigRegister16.size + firstByte + 4)
        loop = BigRegister16.size + firstByte + 8
    }
    
    func initMemory() -> IMacros {
        body {
            tmpValue.initMemory()
            value.initMemory()
            currentNumber.initMemory()
        }
    }
    
    private func load(workRegister: BigRegister16) -> IMacros {
        let cases = (0...15).map { index in
            SwitchCase(index) {
                getValue(workRegister: workRegister, for: Int(index))
            }
        }
        return body {
            currentNumber.copy(to: tmpValue)
            Switch(cell: tmpValue, cases)
        }
    }
    
    func startFullList() -> IMacros {
        body {
            Set(index: currentNumber.value, 15)
        }
    }
    
    func startShortList() -> IMacros {
        body {
            Set(index: currentNumber.value, 7)
        }
    }
    
    func runLoop(workRegister: BigRegister16, _ content: (_ value: BigRegister16, _ stop: () -> IMacros) -> IMacros) -> IMacros {
        body {
            Set(index: loop, 1)
            SafeLoop(index: loop) {
                load(workRegister: workRegister)
                content(value, {
                    Set(index: loop, 0)
                })
                currentNumber.ifZero {
                    Set(index: loop, 0)
                }
                currentNumber.dec()
            }
        }
    }
    
    func getValue(workRegister: BigRegister16, for power: Int) -> IMacros {
        let full = UInt16(0x1 << power)

        return body {
            workRegister.set(full)
            value.set(full)
        }
    }
}

