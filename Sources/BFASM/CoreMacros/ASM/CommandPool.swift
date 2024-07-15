class CommandPool {
    private var locks = Swift.Set<Int>()
    private(set) var commands: [Command] = []
    private let allCommands: Commands = Commands()
    private let vm: VirtualMachine
    
    private(set) lazy var parser = CommandParser(commands: commands, vm: vm)
    private(set) lazy var executor = CommandExecutor(commands: commands, vm: vm)

    init(vm: VirtualMachine) {
        self.vm = vm
        locks.insert(0)
        commands.append(allCommands.run)
        commands.append(allCommands.comment)

        self.addCommand(allCommands.move)
        self.addCommand(allCommands.inc)
        self.addCommand(allCommands.dec)
        self.addCommand(allCommands.add)
        self.addCommand(allCommands.sub)
        self.addCommand(allCommands.mul)
        self.addCommand(allCommands.div)
        self.addCommand(allCommands.mod)

        self.addCommand(allCommands.exit)
    }

    private func addCommand(_ command: Command) {
        var index: Int? = nil
        for i in 1...255 {
            if command.actions.isEmpty && i < 0 {
                continue
            }
            if command.actions.contains(where: {
                variations in variations.localIndex + i < 0 || locks.contains(variations.localIndex + i)
            }) {
                continue
            }
            index = i
            break
        }
        guard let index else {
            fatalError()
        }
        command.baseOpCode = index
        command.actions.forEach { variations in
            locks.insert(variations.localIndex + index)
        }
        commands.append(command)
    }
}

class Command2Pool {
    let vm: VirtualMachine
    
    let allCommands: Commands2
    private(set) var commands: [Command2] = []
    
    private(set) var count: Int = 0

    init(vm: VirtualMachine, commands: Commands2 = .init()) {
        self.vm = vm
        self.allCommands = commands
        self.commands.append(commands.run)
        self.commands.append(commands.comment)
        self.commands.append(commands.move)
        self.commands.append(commands.inc)
        self.commands.append(commands.dec)
        self.commands.append(commands.add)
        self.commands.append(commands.sub)
        self.commands.append(commands.mul)
        self.commands.append(commands.mod)
        self.commands.append(commands.div)
        self.commands.append(commands.exit)
        self.commands.append(commands.cmp)
        
        self.commands.append(commands.jmp)

        self.commands.append(commands.jne)
        self.commands.append(commands.jae)
        self.commands.append(commands.jbe)
        self.commands.append(commands.ja)
        self.commands.append(commands.je)
        self.commands.append(commands.jb)
        
        self.commands.append(commands.input)
        self.commands.append(commands.resIn)
        self.commands.append(commands.output)
        
        self.commands.append(commands.fPop)
        self.commands.append(commands.fPush)
        self.commands.append(commands.bPop)
        self.commands.append(commands.bPush)
        
        self.commands.append(commands.push)
        self.commands.append(commands.pop)
        self.commands.append(commands.get)

        self.commands.append(commands.call)
        self.commands.append(commands.ret)

        self.commands.sort { $0.sortNumber < $1.sortNumber }
        var index: Int = 1
        self.commands.forEach { command in
            if command.loadAction == nil {
                command.baseCode = index
                index += 1
            }
            if count == 0 && command.sortNumber == 1 {
                count = index
            }
        }
    }
}
