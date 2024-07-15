struct CommandExecutor {
    let commands: [Command]
    let vm: VirtualMachine

    init(commands: [Command], vm: VirtualMachine) {
        self.commands = commands
        self.vm = vm
    }

    func runCommand() -> IMacros {
        let cases = commands.flatMap({
            command in command.actions.map({ (command, $0) })
        }).map { container in
            SwitchCase(UInt8(container.0.baseOpCode + container.1.localIndex - 1)) {
                container.1.action(vm)
            }
        }
        return body {
            vm.memory.readValue(address: vm.indexCommand, value: vm.command)
            vm.indexCommand.inc16()
            Switch(cell: vm.command.lowCell, cases) {
                Set(index: vm.flags.runFlag, 0)
                Set(index: vm.flags.errorFlag, 1)
                Print(vm.tmp0.lowCell.zero1, text: "\nIncorrect op-code")
            }
        }
    }

    func runProgram() -> IMacros {
        body {
            Add(index: vm.flags.errorFlag, -1)
            SafeLoop(index: vm.flags.errorFlag) {
                Add(index: vm.flags.runFlag, 1)
                Add(index: vm.flags.errorFlag, 0)
                SafeLoop(index: vm.flags.runFlag) {
                    runCommand()
                }
                Set(index: vm.flags.runFlag, 1)
                SafeLoop(index: vm.flags.errorFlag) {
                    Print(vm.tmp0.lowCell.zero1, text: "\nAn error occurred during program execution: ")
                    Set(index: vm.flags.runFlag, 0)
                    Set(index: vm.flags.errorFlag, 0)
                }
                SafeLoop(index: vm.flags.runFlag) {
                    Print(vm.tmp0.lowCell.zero1, text: "\nThe program completed successfully")
                    Set(index: vm.flags.runFlag, 0)
                }
            }
        }
    }
}
