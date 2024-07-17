import Foundation
@testable import BFASM

@discardableResult
func brainfuckInterpreter(
    input: String = "",
    _ memory: inout [UInt8],
    fast: Bool = false,
    breakPoints: [String: (_ memory: inout [UInt8], _ currentPoint: Int) -> Void] = [:],
    @MacrosBuilder _ code: () -> IMacros
) -> String {
    return brainfuckInterpreter(code: code(), input: input, memory: &memory, fast: fast, breakPoints: breakPoints)
}

@discardableResult
func brainfuckInterpreter(code: IMacros, input: String = "", memory: inout [UInt8], fast: Bool = false, breakPoints: [String: (_ memory: inout [UInt8], _ currentPoint: Int) -> Void] = [:]) -> String {

    let pool = BreakPointPool(breakPoints: breakPoints)
    let code = code.generateCode(manager: SelectedCellManager(activeBreakPoints: pool))
    if fast {
        let commands = compileBrainfuck(code: code)
        return executeBrainfuck(commands: commands, input: input, memory: &memory, breakPoints: pool.breakPoints)
    }
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

enum BFCommand {
    case add(_ value: Int)
    case move(_ value: Int)
    case jmpIfZero(_ jmp: Int) // [
    case jmpIfNotZero(_ jmp: Int) // ]
    case out
    case `in`
    case breakPoint(_ text: String)
}

func compileBrainfuck(code: String) -> [BFCommand] {
    var commands: [BFCommand] = []
    var pc = code.startIndex
    var loopStack: [Int] = []

    while pc < code.endIndex {
        let command = code[pc]

        switch command {
        case ">", "<":
            var move = 0
            while code[pc] == ">" || code[pc] == "<" {
                if code[pc] == ">" {
                    move += 1
                } else {
                    move -= 1
                }
                pc = code.index(after: pc)
            }
            commands.append(.move(move))
            continue
        case "+", "-":
            var value = 0
            while code[pc] == "+" || code[pc] == "-" {
                if code[pc] == "+" {
                    value += 1
                } else {
                    value -= 1
                }
                pc = code.index(after: pc)
            }
            commands.append(.add(value))
            continue
        case ".":
            commands.append(.out)
        case ",":
            commands.append(.in)
        case "[":
            loopStack.append(commands.count)
            commands.append(.jmpIfZero(0)) // временное значение, будет исправлено позже
        case "]":
            if let start = loopStack.popLast() {
                commands[start] = .jmpIfZero(commands.count + 1)
                commands.append(.jmpIfNotZero(start))
            }
        case "#":
            pc = code.index(after: pc)
            var idText = ""
            while (code[pc] != ";") {
                idText += String(code[pc])
                pc = code.index(after: pc)
            }
            commands.append(.breakPoint(idText))
        default:
            break
        }
        pc = code.index(after: pc)
    }
    return commands
}

@discardableResult
func executeBrainfuck(commands: [BFCommand], input: String = "", memory: inout [UInt8], breakPoints: [String: (_ memory: inout [UInt8], _ currentPoint: Int) -> Void] = [:]) -> String {
    var pointer = 0
    var inputPointer = input.startIndex
    var output = ""
    var pc = 0

    while pc < commands.count {
        let command = commands[pc]

        switch command {
        case .move(let value):
            pointer += value
            pointer = (pointer + memory.count) % memory.count
        case .add(let value):
            memory[pointer] = UInt8((Int(memory[pointer]) + value) & 0xff)
        case .out:
            output.append(Character(UnicodeScalar(memory[pointer])))
            if output.last == "\n" {
                let row = output.components(separatedBy: "\n").dropLast().last ?? ""
                print(row)
            }
        case .in:
            if inputPointer < input.endIndex {
                memory[pointer] = UInt8(input[inputPointer].asciiValue!)
                inputPointer = input.index(after: inputPointer)
            } else {
                memory[pointer] = 0
            }
        case .jmpIfZero(let jmp):
            if memory[pointer] == 0 {
                pc = jmp - 1
            }
        case .jmpIfNotZero(let jmp):
            if memory[pointer] != 0 {
                pc = jmp - 1
            }
        case .breakPoint(let text):
            breakPoints[text]?(&memory, pointer)
        }
        pc += 1
    }
    
    return output
}
