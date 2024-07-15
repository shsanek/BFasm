let allCommandArgumentPatterns: [CommandArgumentPatternTemplate] = [
    .init(baseShift: 0, combination: .init(argument1: .register, argument2: nil)),

    .init(baseShift: 3, combination: .init(argument1: .register, argument2: .const)),
    .init(baseShift: 6, combination: .init(argument1: .register, argument2: .memory)),
    .init(baseShift: 12, combination: .init(argument1: .register, argument2: .register)),

    .init(baseShift: 18, combination: .init(argument1: .memory, argument2: .const)),
    .init(baseShift: 21, combination: .init(argument1: .memory, argument2: .register)),
    
    .init(baseShift: 27, combination: .init(argument1: .const, argument2: nil)),
    .init(baseShift: 28, combination: .init(argument1: nil, argument2: nil)),
]

enum CommandArgumentType: Hashable {
    case register
    case memory
    case const
}

enum CommandArgumentCombinationAction {
    case twoArgument(
        _ argument1: CommandArgumentType,
        _ argument2: CommandArgumentType,
        action: (VirtualMachine, BigRegister16, BigRegister16) -> IMacros
    )

    case oneArgument(
        _ argument1: CommandArgumentType,
        action: (VirtualMachine, BigRegister16) -> IMacros
    )

    case noArgument(
        action: (VirtualMachine) -> IMacros
    )
}


struct CommandArgumentCombination: Hashable {
    let argument1: CommandArgumentType?
    let argument2: CommandArgumentType?
}

struct CommandVersionContainer {
    let localIndex: Int
    let action: (VirtualMachine) -> IMacros
}

struct CommandArgumentPatternTemplate {
    let baseShift: Int
    let subcommandsCount: Int
    let combination: CommandArgumentCombination
    let generateAllVersion: (@escaping (VirtualMachine, BigRegister16, BigRegister16) -> IMacros) -> [CommandVersionContainer]
    
    
    init(baseShift: Int, combination: CommandArgumentCombination) {
        self.baseShift = baseShift
        self.combination = combination
        if combination.argument1 == .const {
            assert(combination.argument2 == nil)
            generateAllVersion = { Self.oneConstAction(baseShift: baseShift, $0) }
            self.subcommandsCount = 1
        } else if combination.argument1 != nil {
            if let arg1 = combination.argument2 {
                if arg1 == .const {
                    self.subcommandsCount = 3
                    generateAllVersion = { Self.oneRegisterAction(baseShift: baseShift, needConst: true, $0) }
                } else {
                    self.subcommandsCount = 6
                    generateAllVersion = { Self.twoRegisterAction(baseShift: baseShift, $0) }
                }
            } else {
                self.subcommandsCount = 3
                generateAllVersion = { Self.oneRegisterAction(baseShift: baseShift, needConst: true, $0) }
            }
        } else {
            assert(combination.argument2 == nil)
            self.subcommandsCount = 1
            generateAllVersion = { Self.noArgs(baseShift: baseShift, $0) }
        }
    }
    
    static func noArgs(
        baseShift: Int,
        _ action: @escaping (VirtualMachine, BigRegister16, BigRegister16) -> IMacros
    ) -> [CommandVersionContainer] {
        [
            .init(localIndex: baseShift, action: { vm in
                body {
                    Self.readConst(vm)
                    action(vm, vm.operand, vm.operand)
                }
            })
        ]
    }
    
    static func oneConstAction(
        baseShift: Int,
        _ action: @escaping (VirtualMachine, BigRegister16, BigRegister16) -> IMacros
    ) -> [CommandVersionContainer] {
        [
            .init(localIndex: baseShift, action: { vm in
                body {
                    Self.readConst(vm)
                    action(vm, vm.operand, vm.operand)
                }
            })
        ]
    }
    
    static func twoRegisterAction(
        baseShift: Int,
        _ action: @escaping (VirtualMachine, BigRegister16, BigRegister16) -> IMacros
    ) -> [CommandVersionContainer] {
        [
            .init(localIndex: baseShift, action: { vm in
                action(vm, vm.register0, vm.register1)
            }),
            .init(localIndex: baseShift + 1, action: { vm in
                action(vm, vm.register0, vm.register2)
            }),
            .init(localIndex: baseShift + 2, action: { vm in
                action(vm, vm.register1, vm.register0)
            }),
            .init(localIndex: baseShift + 3, action: { vm in
                action(vm, vm.register1, vm.register2)
            }),
            .init(localIndex: baseShift + 4, action: { vm in
                action(vm, vm.register2, vm.register0)
            }),
            .init(localIndex: baseShift + 5, action: { vm in
                action(vm, vm.register2, vm.register1)
            })
        ]
    }
    
    static func readConst(_ vm: VirtualMachine) -> IMacros {
        body {
            vm.memory.readValue(address: vm.indexCommand, value: vm.operand)
            vm.indexCommand.inc16()
        }
    }
    
    static func oneRegisterAction(
        baseShift: Int,
        needConst: Bool,
        _ action: @escaping (VirtualMachine, BigRegister16, BigRegister16) -> IMacros
    ) -> [CommandVersionContainer] {
        [
            .init(localIndex: baseShift, action: { vm in
                body {
                    if needConst {
                        readConst(vm)
                    }
                    action(vm, vm.register0, vm.operand)
                }
            }),
            .init(localIndex: baseShift + 1, action: { vm in
                body {
                    if needConst {
                        readConst(vm)
                    }
                    action(vm, vm.register1, vm.operand)
                }
            }),
            .init(localIndex: baseShift + 2, action: { vm in
                body {
                    if needConst {
                        readConst(vm)
                    }
                    action(vm, vm.register2, vm.operand)
                }
            })
        ]
    }
}
