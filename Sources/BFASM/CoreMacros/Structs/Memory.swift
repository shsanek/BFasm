struct Memory {
    private let index: Int
    let firstCell: MemoryCell
    
    init(firstByte: Int) {
        self.index = firstByte
        self.firstCell = MemoryCell(firstByte: firstByte)
    }
    
    static let memoryBreakPointInit = "memoryBreakPointInit"
    static let memoryBreakPointDone = "memoryBreakPointDone"
    static let memoryBreakPointEndMove = "memoryBreakPointEndMove"

    static let memoryBreakPointBigMove = "memoryBreakPointBigMove"
    static let memoryBreakPointLittleMove = "memoryBreakPointLittleMove"
    
    static let memoryBreakPointBigBack = "memoryBreakPointBigBack"
    static let memoryBreakPointLittleBack = "memoryBreakPointLittleBack"

    
    func writeValue(address: BigRegister16, value: BigRegister16) -> IMacros {
        body {
            address.copy(to: firstCell.address)
            value.copy(to: firstCell.moveData)
            BreakPoint(Self.memoryBreakPointInit)
            moveToAddress(rightHandle: { (current, next) in
                current.moveData.move(to: next.moveData)
            }, endHandler: { (current) in
                current.moveData.move(to: current.data)
            })
            BreakPoint(Self.memoryBreakPointDone)
        }
    }
    
    func moveInValue(address: BigRegister16, value: BigRegister16) -> IMacros {
        body {
            address.copy(to: firstCell.address)
            value.move(to: firstCell.moveData)
            BreakPoint(Self.memoryBreakPointInit)
            moveToAddress(rightHandle: { (current, next) in
                current.moveData.move(to: next.moveData)
            }, endHandler: { (current) in
                current.moveData.move(to: current.data)
            })
            BreakPoint(Self.memoryBreakPointDone)
        }
    }
    
    func readValue(address: BigRegister16, value: BigRegister16) -> IMacros {
        body {
            address.copy(to: firstCell.address)
            BreakPoint(Self.memoryBreakPointInit)
            moveToAddress(leftHandle: { (current, back) in
                current.moveData.move(to: back.moveData)
            }, endHandler: { cell in
                cell.data.copy(to: cell.moveData, tmp: cell.address.lowCell.index - 1)
            })
            BreakPoint(Self.memoryBreakPointDone)
            firstCell.moveData.copy(to: value)
        }
    }
    
    func writeValue(address: Data2ByteCell, value: Data2ByteCell) -> IMacros {
        body {
            address.move(to: firstCell.address)
            value.move(to: firstCell.moveData)
            BreakPoint(Self.memoryBreakPointInit)
            moveToAddress(rightHandle: { (current, next) in
                current.moveData.move(to: next.moveData)
            }, endHandler: { (current) in
                current.moveData.move(to: current.data)
            })
            BreakPoint(Self.memoryBreakPointDone)
        }
    }
    
    func readValue(address: Data2ByteCell, value: Data2ByteCell) -> IMacros {
        body {
            address.copy(to: firstCell.address)
            BreakPoint(Self.memoryBreakPointInit)
            moveToAddress(leftHandle: { (current, back) in
                current.moveData.move(to: back.moveData)
            }, endHandler: { cell in
                body {
                    cell.data.copy(to: cell.moveData, tmp: cell.address.lowCell.zero0)
                }
            })
            BreakPoint(Self.memoryBreakPointDone)
            firstCell.moveData.move(to: value)
        }
    }
    
    func memoryProcess(address: Data2ByteCell, value: Data2ByteCell, commandIndex: Int) -> IMacros {
        body {
            address.copy(to: firstCell.address)
            FastIf(index: commandIndex) {
                value.move(to: firstCell.moveData)
                Set(index: firstCell.commandFlag, 1)
            }
            BreakPoint(Self.memoryBreakPointInit)
            moveToAddress(leftHandle: { (current, back) in
                FastIf(index: current.commandFlag) {
                    Set(index: back.commandFlag, 1)
                    current.moveData.unsafeMove(to: back.moveData)
                }
            }, rightHandle: { (current, next) in
                FastIf(index: current.commandFlag) {
                    current.moveData.unsafeMove(to: next.moveData)
                    Set(index: next.commandFlag, 1)
                }
            }, endHandler: { (current) in
                body {
                    Set(index: current.address.lowCell.zero0, 1)
                    FastIf(index: current.commandFlag) {
                        current.moveData.move(to: current.data)
                        Set(index: current.address.lowCell.zero0, 0)
                    }
                    FastIf(index: current.address.lowCell.zero0) {
                        current.data.copy(to: current.moveData, tmp: current.address.highCell.zero0)
                        Set(index: current.commandFlag, 1)
                    }
                }
            })
            BreakPoint(Self.memoryBreakPointDone)
            FastIf(index: firstCell.commandFlag) {
                firstCell.moveData.move(to: value)
            }
        }
    }
    
    private func moveToRight(
        rightHandle: (_ current: MemoryCell, _ next: MemoryCell) -> IMacros = { _, _ in emptyBody }
    ) -> IMacros {
        let cell = MemoryCell(firstByte: 0)
        let shortNext = MemoryCell(firstByte: MemoryCell.size)
        let longNext = MemoryCell(firstByte: MemoryCell.size * 256)
        
        return body {
            Set(index: cell.backFlagIndex, 0)
            Set(index: cell.nextFlagIndex, 1)
            SafeLoop(index: cell.nextFlagIndex) {
                cell.address.highCell.if(requiredInit: true) {
                    cell.address.highCell.dec()
                    cell.address.move(to: longNext.address)
                    Set(index: cell.nextFlagIndex, 0)
                    
                    rightHandle(cell, longNext)
                    
                    UnsafeMove(MemoryCell.size * 256)
                    
                    Add(index: cell.backFlagIndex, 1)
                    Add(index: cell.nextFlagIndex, 1)

                    BreakPoint(Self.memoryBreakPointBigMove)
                } zero: {
                    Set(index: cell.nextFlagIndex, 1)

                    SafeLoop(index: cell.nextFlagIndex) {
                        cell.address.lowCell.if(requiredInit: true) {
                            Set(index: cell.nextFlagIndex, 0)

                            cell.address.lowCell.dec()
                            MoveValue(dest: shortNext.address.lowCell.index, src: cell.address.lowCell.index)

                            rightHandle(cell, shortNext)
        
                            UnsafeMove(MemoryCell.size)

                            Add(index: cell.backFlagIndex, 2)
                            Add(index: cell.nextFlagIndex, 1)

                            BreakPoint(Self.memoryBreakPointLittleMove)
                        } zero: {
                            SetZero(cell.nextFlagIndex)
                        }
                        SetCell(cell.nextFlagIndex)
                    }
                }
                SetCell(cell.nextFlagIndex)
            }
        }
    }
    
    private func moveToLeft(
        leftHandle: (_ current: MemoryCell, _ back: MemoryCell) -> IMacros = { _, _ in emptyBody }
    ) -> IMacros {
        let cell = MemoryCell(firstByte: 0)
        
        let shortBack = MemoryCell(firstByte: -MemoryCell.size)
        let longBack = MemoryCell(firstByte: -MemoryCell.size * 256)
        
        return body {            
            SetCell(cell.backFlagIndex)
            SafeLoop(index: cell.backFlagIndex) {
                Set(index: cell.address.lowCell.index, 1)
                Set(index: cell.address.highCell.index, 0)
                
                Add(index: cell.backFlagIndex, -1)
                SafeLoop(index: cell.backFlagIndex) {
                    Set(index: cell.address.highCell.index, 1)
                    Set(index: cell.address.lowCell.index, 0)
                    Set(index: cell.backFlagIndex, 0)
                }
                
                SetCell(cell.address.highCell.index)
                SafeLoop(index: cell.address.highCell.index) {
                    leftHandle(cell, shortBack)
                    
                    UnsafeMove(-MemoryCell.size)
                    
                    Set(index: cell.address.highCell.index, 0)
                    BreakPoint(Self.memoryBreakPointLittleBack)
                }
                
                SetCell(cell.address.lowCell.index)
                SafeLoop(index: cell.address.lowCell.index) {
                    Set(index: cell.backFlagIndex, 1)
                    SafeLoop(index: cell.backFlagIndex) {
                        leftHandle(cell, longBack)

                        UnsafeMove(-MemoryCell.size * 256)
                        
                        SetCell(cell.backFlagIndex)
                        BreakPoint(Self.memoryBreakPointBigBack)
                    }
                    Set(index: cell.address.lowCell.index, 0)
                }
                SetCell(cell.backFlagIndex)
            }
        }
    }
    
    private func moveToAddress(
        leftHandle: (_ current: MemoryCell, _ back: MemoryCell) -> IMacros = { _, _ in emptyBody },
        rightHandle: (_ current: MemoryCell, _ next: MemoryCell) -> IMacros = { _, _ in emptyBody },
        endHandler: (_ current: MemoryCell) -> IMacros = { _ in emptyBody }
    ) -> IMacros {
        let cell = MemoryCell(firstByte: 0)
        
        return ActiveCell(index) {
            LocalCell {
                moveToRight(rightHandle: rightHandle)
                endHandler(cell)
                SetCell(cell.index)
                BreakPoint(Self.memoryBreakPointEndMove)
                moveToLeft(leftHandle: leftHandle)
            }
        }
    }
}
