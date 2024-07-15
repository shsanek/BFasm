func moveOptimization(code: String) -> String {
    let code = code.map({ $0 })
    var result: String = ""
    var move = 0
    var index: Int = 0
    while index < code.count {
        defer {
            index += 1
        }
        if code[index] == ">" {
            move += 1
        } else if code[index] == "<" {
            move -= 1
        } else if code[index] == "#" {
            assert(false)
        } else {
            if move > 0 {
                result.append(Array(repeating: ">", count: move).joined())
            } else if move < 0 {
                result.append(Array(repeating: "<", count: -move).joined())
            }
            move = 0
            result.append(code[index])
        }
    }
    return result
}
