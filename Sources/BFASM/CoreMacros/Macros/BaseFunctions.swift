func SetZero(_ index: Int? = nil) -> IMacros {
    UnsafeMacros {
        if let index {
            SetCell(index)
        }
        "[-]"
    }
}

func Set(index: Int? = nil, _ value: Int) -> IMacros {
    body {
        if let index {
            SetCell(index)
        }
        SetZero()
        Add(value)
    }
}

func Add(index: Int? = nil, _ value: Int) -> IMacros {
    body {
        if let index {
            SetCell(index)
        }
        if value > 0 {
            Array(repeating: "+", count: value).joined()
        }
        if value < 0 {
            Array(repeating: "-", count: -value).joined()
        }
    }
}

func MoveValue(dest: Int, src: Int) -> IMacros {
    if dest == src {
        return emptyBody
    }
    return body {
        SetZero(dest)
        SetCell(src)
        SafeLoop(index: src) {
            Add(index: dest, 1)
            Add(index: src, -1)
        }
    }
}


func UnsafeMoveValue(dest: Int, src: Int) -> IMacros {
    if dest == src {
        return emptyBody
    }
    return body {
        SafeLoop(index: src) {
            Add(index: dest, 1)
            Add(index: src, -1)
        }
    }
}

func CopyValue(dest: Int, src: Int, tmp: Int) -> IMacros {
    if dest == src {
        return emptyBody
    }
    assert(Set([dest, src, tmp]).count == 3)
    return body {
        SetZero(dest)
        SetZero(tmp)
        SetCell(src)
        SafeLoop(index: src) {
            Add(index: dest, 1)
            Add(index: tmp, 1)
            Add(index: src, -1)
        }
        SetCell(tmp)
        SafeLoop(index: tmp) {
            Add(index: src, 1)
            Add(index: tmp, -1)
        }
    }
}

class BreakPointPool {
    var breakPoints: [String: (_ memory: inout [UInt8], _ currentPoint: Int) -> Void]
    
    init(breakPoints: [String: (_ memory: inout [UInt8], _ currentPoint: Int) -> Void] = [:]) {
        self.breakPoints = breakPoints
    }
}

struct BreakPoint: IMacros {
    let id: String
    
    init(_ id: String) {
        self.id = id
    }
    
    func generateCode(manager: SelectedCellManager) -> String {
        if manager.activeBreakPoints.breakPoints[id] != nil {
            return "#\(id);"
        }
        return ""
    }
    func checkShift(manager: SelectedCellManager) -> Int? {
        return 0
    }
}

import Foundation

struct CustomBreakPoint: IMacros {
    let id: String
    let block: (_ memory: inout [UInt8], _ currentPoint: Int) -> Void
    
    init(_ action: @escaping  (_ memory: inout [UInt8], _ currentPoint: Int) -> Void) {
        self.id = UUID().uuidString
        self.block = action
    }
    
    func generateCode(manager: SelectedCellManager) -> String {
        manager.activeBreakPoints.breakPoints[id] = block
        return "#\(id);"
    }
    func checkShift(manager: SelectedCellManager) -> Int? {
        return 0
    }
}
