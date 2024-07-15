struct CommandParser {
    private let commands: [Command]
    private let vm: VirtualMachine
    
    init(commands: [Command], vm: VirtualMachine) {
        self.commands = commands
        self.vm = vm
    }
    
    func loadProgram() -> IMacros {
        body {
            Set(index: vm.flags.errorFlag, 0)
            Set(index: vm.flags.runFlag, 1)
            SafeLoop(index: vm.flags.runFlag) {
                parseCommand()
            }
            Set(index: vm.flags.runFlag, 1)
            FastIf(index: vm.flags.errorFlag) {
                Print(vm.tmp0.lowCell.zero1, text: "\nAn error occurred while loading the program")
                Set(index: vm.flags.runFlag, 0)
            }
            Set(index: vm.flags.errorFlag, 1)
            FastIf(index: vm.flags.runFlag) {
                Print(vm.tmp0.lowCell.zero1, text: "\nProgram loaded successfully")
                vm.indexCommand.set(0)
                Set(index: vm.flags.runFlag, 0)
                Set(index: vm.flags.errorFlag, 0)
            }
        }
    }
    
    func parseCommand() -> IMacros {
        let cases: [StringSwitchCase] = commands.map { command in
            StringSwitchCase(command.name) {
                if let action = command.specialAction {
                    action(vm)
                }
                vm.command.set(UInt16(command.baseOpCode))
            }
        }
        return body {
            vm.command.set(0)
            ReadStringSwitch(vm: vm, cases) {
                Set(index: vm.flags.runFlag, 0)
                Set(index: vm.flags.errorFlag, 1)
                Print(vm.tmp0.lowCell.zero1, text: "\nIncorrect command")
            }
            SafeLoop(index: vm.command.lowCell.value) {
                vm.command.lowCell.dec()
                CommandArgumentReader(vm: vm) {
                    Set(index: vm.flags.runFlag, 0)
                    Set(index: vm.flags.errorFlag, 1)
                    Print(vm.tmp0.lowCell.zero1, text: "\nIncorrect arguments")
                }
                vm.command.set(0)
            }
        }
    }
}

struct Command2Parser {
    private let commands: [Command2]
    private let vm: VirtualMachine
    
    init(commands: [Command2], vm: VirtualMachine) {
        self.commands = commands
        self.vm = vm
    }
    
    func loadProgram() -> IMacros {
        body {
            Set(index: vm.flags.errorFlag, 0)
            Set(index: vm.flags.runFlag, 1)
            SafeLoop(index: vm.flags.runFlag) {
                parseCommand()
            }
            
            Set(index: vm.flags.overFlag, 1)
            FastIf(index: vm.flags.errorFlag) {
                Print(vm.tmp0.lowCell.zero1, text: "\nAn error occurred while loading the program")
                Set(index: vm.flags.runFlag, 0)
                Set(index: vm.flags.overFlag, 0)
            }
            Set(index: vm.flags.errorFlag, 1)
            FastIf(index: vm.flags.overFlag) {
                Print(vm.tmp0.lowCell.zero1, text: "\nProgram loaded successfully\nI/O:\n")
                vm.indexCommand.copy(to: vm.stack)
                vm.indexCommand.set(0)
                Set(index: vm.flags.errorFlag, 0)
                Set(index: vm.flags.runFlag, 1)
            }
        }
    }
    
    func parseCommand() -> IMacros {
        let cases: [StringSwitchCase] = commands.map { command in
            StringSwitchCase(command.name) {
                if let action = command.loadAction {
                    action(vm)
                }
                vm.command.set(UInt16(command.baseCode))
            }
        }
        return body {
            vm.command.set(0)
            ReadStringSwitch(vm: vm, cases) {
                Set(index: vm.flags.runFlag, 0)
                Set(index: vm.flags.errorFlag, 1)
                Print(vm.tmp0.lowCell.zero1, text: "\nIncorrect command")
            }
            SafeLoop(index: vm.command.lowCell.value) {
                vm.command.lowCell.dec()
                Command2ArgumentReader(vm: vm) {
                    Set(index: vm.flags.runFlag, 0)
                    Set(index: vm.flags.errorFlag, 1)
                    Print(vm.tmp0.lowCell.zero1, text: "\nIncorrect arguments")
                }.parseArgument()
                vm.command.set(0)
            }
        }
    }
}
