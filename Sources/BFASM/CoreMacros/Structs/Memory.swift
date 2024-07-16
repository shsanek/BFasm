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
    
    func readValue(address: BigRegister16, value: BigRegister16) -> IMacros {
        body {
            address.copy(to: firstCell.address)
            BreakPoint(Self.memoryBreakPointInit)
            moveToAddress(leftHandle: { (current, back) in
                current.moveData.move(to: back.moveData)
            }, endHandler: { cell in
                cell.data.copy(to: cell.moveData, tmp: cell.address.lowValue)
            })
            firstCell.moveData.move(to: value)
            BreakPoint(Self.memoryBreakPointDone)
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
            address.copy(to: firstCell.address, tmp: firstCell.flags.index)
            BreakPoint(Self.memoryBreakPointInit)
            moveToAddress(leftHandle: { (current, back) in
                current.moveData.move(to: back.moveData)
            }, endHandler: { cell in
                body {
                    cell.data.copy(to: cell.moveData, tmp: cell.address.lowValue)
                }
            })
            firstCell.moveData.move(to: value)
            BreakPoint(Self.memoryBreakPointDone)
        }
    }
    
    func memoryProcess(address: Data2ByteCell, value: Data2ByteCell, commandIndex: Int) -> IMacros {
        body {
            address.copy(to: firstCell.address, tmp: firstCell.flags.index)
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
                    Set(index: current.address.lowValue, 1)
                    FastIf(index: current.commandFlag) {
                        current.moveData.move(to: current.data)
                        Set(index: current.address.lowValue, 0)
                    }
                    FastIf(index: current.address.lowValue) {
                        current.data.copy(to: current.moveData, tmp: current.address.highValue)
                        Set(index: current.commandFlag, 1)
                    }
                }
            })
            BreakPoint(Self.memoryBreakPointDone)
            FastIf(index: firstCell.commandFlag) {
                firstCell.moveData.move(to: value)
            }
            CustomBreakPoint { memory, currentPoint in
                assert(currentPoint == firstCell.commandFlag)
                assert(memory.validMemory(VirtualMachine()))
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
            SafeLoop(index: cell.address.highValue) {
                Add(index: cell.address.highValue, -1)
                cell.address.move(to: longNext.address)
                rightHandle(cell, longNext)
                UnsafeMove(MemoryCell.size * 256)
                Add(index: cell.flags.highValue, 1)
                BreakPoint(Self.memoryBreakPointBigMove)
            }
            SafeLoop(index: cell.address.lowValue) {
                Add(index: cell.address.lowValue, -1)
                cell.address.move(to: shortNext.address)
                rightHandle(cell, shortNext)
                UnsafeMove(MemoryCell.size)
                Add(index: cell.flags.lowValue, 1)
                BreakPoint(Self.memoryBreakPointLittleMove)
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
            SafeLoop(index: cell.flags.lowValue) {
                leftHandle(cell, shortBack)
                Add(index: cell.flags.lowValue, -1)
                UnsafeMove(-MemoryCell.size)
                BreakPoint(Self.memoryBreakPointLittleBack)
            }
            SafeLoop(index: cell.flags.highValue) {
                leftHandle(cell, longBack)
                Add(index: cell.flags.highValue, -1)
                UnsafeMove(-MemoryCell.size * 256)
                BreakPoint(Self.memoryBreakPointBigBack)
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
