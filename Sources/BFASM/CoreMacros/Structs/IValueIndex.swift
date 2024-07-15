struct OneByteCell: IValueIndex {
    let index: Int
    
    init(index: Int) {
        self.index = index
    }
}

protocol IValueIndex {
    var index: Int { get }
}

extension IValueIndex {
    func inc() -> IMacros {
        ActiveCell(index) {
            Add(1)
        }
    }
    
    func dec() -> IMacros {
        ActiveCell(index) {
            Add(-1)
        }
    }
    
    func add(_ value: Int) -> IMacros {
        ActiveCell(index) {
            Add(value)
        }
    }
    
    func set(_ value: Int) -> IMacros {
        ActiveCell(index) {
            Set(value)
        }
    }
}

protocol I3ByteCell {
    var value: Int { get }
    
    var zero0: Int { get }
    var one0: Int { get }
}
 
extension I3ByteCell {
    func init3Memory() -> IMacros {
        body {
            SetZero(zero0)
            Set(index: one0, 1)
            SetCell(value)
        }
    }
    
    func copy(to index: Int) -> IMacros {
        CopyValue(dest: index, src: value, tmp: zero0)
    }
    
    func copy(to cell: I3ByteCell) -> IMacros {
        CopyValue(dest: cell.value, src: value, tmp: zero0)
    }
    
    func move(to cell: I3ByteCell) -> IMacros {
        MoveValue(dest: cell.value, src: value)
    }
}

protocol I4ByteCell: I3ByteCell {
    var zero1: Int { get }
}

extension I4ByteCell {
    func init4Memory() -> IMacros {
        body {
            init3Memory()
            SetZero(zero1)
            SetCell(value)
        }
    }
}
