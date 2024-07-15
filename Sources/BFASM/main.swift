import Foundation

let vm = VirtualMachine()
let pool = Command2Pool(vm: vm)
let fullProgram = body {
    vm.initMemory()
    Print(0, text: "Welcome to BF-ASM. Documentation on the commands can be found here (https://github.com/shsanek/BFasm). Enter your program:\n")
    Command2Parser(commands: pool.commands, vm: vm).loadProgram()
    MicroCore(pool: pool, vm: vm).loop()
}.generateCode(
    manager: SelectedCellManager(activeBreakPoints: BreakPointPool())
)
var o1 = fullProgram

func splitString(_ input: String, length: Int) -> [String] {
    var result = [String]()
    let strLength = input.count
    
    for i in stride(from: 0, to: strLength, by: length) {
        let start = input.index(input.startIndex, offsetBy: i)
        let end = input.index(start, offsetBy: length, limitedBy: input.endIndex) ?? input.endIndex
        let substring = String(input[start..<end])
        result.append(substring)
    }
    
    return result
}

o1 = splitString(o1, length: 300).joined(separator: "\n")
let path = URL(fileURLWithPath: #filePath).deletingLastPathComponent().path
try o1.write(toFile: "\(path)/../Products/result.bf", atomically: true, encoding: .utf8)
print(o1.count)
