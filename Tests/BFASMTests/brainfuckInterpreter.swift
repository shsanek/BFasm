import Foundation
@testable import BFASM

@discardableResult
func brainfuckInterpreter(
    input: String = "",
    _ memory: inout [UInt8],
    breakPoints: [String: (_ memory: inout [UInt8], _ currentPoint: Int) -> Void] = [:],
    @MacrosBuilder _ code: () -> IMacros
) -> String {
    return brainfuckInterpreter(code: code(), input: input, memory: &memory, breakPoints: breakPoints)
}

@discardableResult
func brainfuckInterpreter(code: IMacros, input: String = "", memory: inout [UInt8], breakPoints: [String: (_ memory: inout [UInt8], _ currentPoint: Int) -> Void] = [:]) -> String {
    let pool = BreakPointPool(breakPoints: breakPoints)
    let code = code.generateCode(manager: SelectedCellManager(activeBreakPoints: pool))
    var pointer = 0
    var inputPointer = input.startIndex
    var output = ""

    var pc = code.startIndex
    
    while pc < code.endIndex {
        let command = code[pc]

        switch command {
        case ">":
            pointer += 1
            if pointer >= memory.count {
                pointer = 0 // цикл по памяти
            }
        case "<":
            pointer -= 1
            if pointer < 0 {
                pointer = memory.count - 1 // цикл по памяти
            }
        case "+":
            memory[pointer] = UInt8((Int(memory[pointer]) + 1) & 0xff)
        case "-":
            memory[pointer] = UInt8((Int(memory[pointer]) - 1) & 0xff)
        case ".":
            output.append(Character(UnicodeScalar(memory[pointer])))
        case ",":
            if inputPointer < input.endIndex {
                memory[pointer] = UInt8(input[inputPointer].asciiValue!)
                inputPointer = input.index(after: inputPointer)
            } else {
                memory[pointer] = 0 // если входные данные закончились
            }
        case "[":
            if memory[pointer] == 0 {
                var openBrackets = 1
                while openBrackets > 0 {
                    pc = code.index(after: pc)
                    if code[pc] == "[" { openBrackets += 1 }
                    if code[pc] == "]" { openBrackets -= 1 }
                }
            }
        case "]":
            if memory[pointer] != 0 {
                var closeBrackets = 1
                while closeBrackets > 0 {
                    pc = code.index(before: pc)
                    if code[pc] == "[" { closeBrackets -= 1 }
                    if code[pc] == "]" { closeBrackets += 1 }
                }
            }
        case "#":
            pc = code.index(after: pc)
            var idText = ""
            while (code[pc] != ";") {
                idText += String(code[pc])
                pc = code.index(after: pc)
            }
            pool.breakPoints[idText]?(&memory, pointer)
            break
        default:
            abort()
            break
        }
        pc = code.index(after: pc)
    }
    
    return output
}

