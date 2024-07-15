struct Data2ByteCell {
    static let size: Int = 2

    let index: Int
    
    init(firstByte: Int) {
        self.index = firstByte
    }
    
    func move(to cell: Data2ByteCell) -> IMacros {
        body {
            MoveValue(dest: cell.index, src: index)
            MoveValue(dest: cell.index + 1, src: index + 1)
        }
    }
    
    func unsafeMove(to cell: Data2ByteCell) -> IMacros {
        body {
            UnsafeMoveValue(dest: cell.index, src: index)
            UnsafeMoveValue(dest: cell.index + 1, src: index + 1)
        }
    }
    
    func copy(to cell: Data2ByteCell, tmp: Int) -> IMacros {
        body {
            CopyValue(dest: cell.index, src: index, tmp: tmp)
            CopyValue(dest: cell.index + 1, src: index + 1, tmp: tmp)
        }
    }
    
    func copy(to register: BigRegister16) -> IMacros {
        body {
            CopyValue(dest: register.lowCell.index, src: index, tmp: register.lowCell.index - 1)
            CopyValue(dest: register.highCell.index, src: index + 1, tmp: register.lowCell.index - 1)
        }
    }
    
    func move(to register: BigRegister16) -> IMacros {
        body {
            MoveValue(dest: register.lowCell.index, src: index)
            MoveValue(dest: register.highCell.index, src: index + 1)
        }
    }
    
    func value(_ memory: inout [UInt8]) -> Int {
        (Int(memory[index]) + Int(memory[index + 1]) * 256)
    }
    
    func info(_ memory: inout [UInt8]) -> String {
        "\(value(&memory))"
    }
}
