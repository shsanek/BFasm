import XCTest
@testable import BFASM
    
class Tests09LoadProgram: XCTestCase {
    func test01LoadProgram() {
        var memory: [UInt8] = .init(repeating: 0, count: 256 * 256 * 50)
        let vm = VirtualMachine()
        let pool = CommandPool(vm: vm)
        brainfuckInterpreter(input: "mov r1 100; # coommeng1  ; mov r2 20; mov ptr r1 r2; inc r1; add r1 r2; run", &memory) {
            vm.initMemory()
            pool.parser.loadProgram()
        }
        let dump = memory.dump(vm).map({ Int($0) })
        let result = [4, 100, 5, 20, 24, 1, 42]
        XCTAssert(Array(dump.prefix(result.count)) == result)
    }
    
    func command(_ command: Command2, arg: Int) -> Int {
        return arg + (command.baseCode - 1)
    }
    
    func test02LoadProgram() {
        var memory: [UInt8] = .init(repeating: 0, count: 256 * 256 * 50)
        let vm = VirtualMachine()
        let pool = Command2Pool(vm: vm)
        let parser = Command2Parser(commands: pool.commands, vm: vm)
        brainfuckInterpreter(input: """
            mov r1 100;
            # coommeng1  ;
            mov r2 20;
            mov ptr r1 r2;
            inc r1;
            add r1 r2;
            run
        """, &memory) {
            vm.initMemory()
            parser.loadProgram()
        }
        let dump = memory.dump(vm).map({ Int($0) })
        let result = [
            command(pool.allCommands.move, arg: command2ArgumentsCombination(.register1, .const)),
            100,
            command(pool.allCommands.move, arg: command2ArgumentsCombination(.register2, .const)),
            20,
            command(pool.allCommands.move, arg: command2ArgumentsCombination(.ptrRegister1, .register2)),
            command(pool.allCommands.inc, arg: command2ArgumentsCombination(.register1, .none)),
            command(pool.allCommands.add, arg: command2ArgumentsCombination(.register1, .register2)),
        ]
        XCTAssert(Array(dump.prefix(result.count)) == result)
    }
}
