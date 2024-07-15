enum MicroCoreCommand: Int {
    case none = 0
    case commandMemory = 1

    case loadValue

    case prepareLoadCommand
    case loadCommand

    case prepareDestination
    case loadDestination
    
    case loadOperand
    
    case runCommand
    
    case saveDestination
}

struct MicroCore {
    let pool: Command2Pool
    let vm: VirtualMachine
    let microCode: MicroCode
    
    init(pool: Command2Pool, vm: VirtualMachine) {
        self.pool = pool
        self.vm = vm
        self.microCode = vm.microCode
    }

    func printInputState(_ memory: inout [UInt8]) {
        let stacks = microCode.commandStack.info(memory: &memory)
        assert(memory[microCode.commandStack.currentCode.value] != 0)
        print("""
            ----------state--------
            run: \(memory[vm.flags.runFlag]) \(microCode.commandStack.convertToCommand(memory[microCode.commandStack.currentCode.value]));
            commandsStack: [\(stacks)];
            operandInfo: isPtr=\(memory[microCode.operandInfo.ptrFlag]), reg=\(memory[microCode.operandInfo.register]), needLoad=\(memory[microCode.operandInfo.needLoad]);
            destinationInfo: isPtr=\(memory[microCode.destinationInfo.ptrFlag]), reg=\(memory[microCode.destinationInfo.register]), needLoad = \(memory[microCode.destinationInfo.needLoad]), needSave=\(memory[microCode.destinationInfo.needSave]);
            values: regValue=\(memory[microCode.value.value]) memValue=\(vm.microCode.memoryValue.info(&memory)), memAddr=\(vm.microCode.memoryAddress.info(&memory)), isPtr=\(memory[vm.microCode.isPtr]);
            registers: operand=\(memory.register16Value(vm.operand)), destination=\(memory.register16Value(vm.destination))
            command: command=\(memory.register16Value(vm.command)) commandIndex=\(memory.register16Value(vm.indexCommand))
            reg: r0=\(vm.r0.info(&memory)), r1=\(vm.r1.info(&memory)), r2=\(vm.r2.info(&memory)), r3=\(vm.r3.info(&memory)), r4=\(vm.r4.info(&memory)), r5=\(vm.r5.info(&memory)), stack=\(memory.register16Value(vm.stack))
            dump: \(memory.dump(vm).prefix(50))
            fStack: \(memory.fastStack(vm))
        """
        )
    }
    func loop() -> IMacros {
        body {
            vm.indexCommand.set(0)
            SafeLoop(index: vm.flags.runFlag) {
                microCode.commandStack.currentCode.set(MicroCoreCommand.prepareLoadCommand.rawValue)
                //                        CustomBreakPoint { memory, currentPoint in
                //                            printInputState(&memory)
                //                        }
                SafeLoop(index: microCode.commandStack.currentCode.value) {
                    Switch(cell: microCode.commandStack.currentCode) {
                        SwitchCase(UInt8(MicroCoreCommand.commandMemory.rawValue)) {
                            microActionMemory()
                        }
                        SwitchCase(UInt8(MicroCoreCommand.loadValue.rawValue)) {
                            microActionLoadValue()
                        }
                        SwitchCase(UInt8(MicroCoreCommand.prepareLoadCommand.rawValue)) {
                            microActionPrepareLoadCommand()
                        }
                        SwitchCase(UInt8(MicroCoreCommand.loadCommand.rawValue)) {
                            microActionLoadCommand()
                        }
                        SwitchCase(UInt8(MicroCoreCommand.prepareDestination.rawValue)) {
                            microActionDestinationPrepare()
                        }
                        SwitchCase(UInt8(MicroCoreCommand.loadDestination.rawValue)) {
                            microActionDestinationLoad()
                        }
                        SwitchCase(UInt8(MicroCoreCommand.loadOperand.rawValue)) {
                            microActionOperandLoad()
                        }
                        SwitchCase(UInt8(MicroCoreCommand.runCommand.rawValue)) {
                            microActionRunCommand()
                        }
                        SwitchCase(UInt8(MicroCoreCommand.saveDestination.rawValue)) {
                            microActionSaveDestination()
                        }
                    }
                    microCode.commandStack.pop()
                }
            }
        }
    }

    func microActionMemory() -> IMacros {
        body {
            vm.memory.memoryProcess(
                address: vm.microCode.memoryAddress,
                value: vm.microCode.memoryValue,
                commandIndex: microCode.memoryCommand
            )
        }
    }

    func microActionSaveDestination() -> IMacros {
        body {
            Set(index: microCode.destinationInfo.needSave, 1)
            
            FastIf(index: microCode.destinationInfo.ptrFlag) {
                Set(index: microCode.destinationInfo.needSave, 0)
                vm.destination.move(to: vm.microCode.memoryValue)
                Set(index: microCode.memoryCommand, 1)
                microCode.commandStack.push(.commandMemory)
            }
            FastIf(index: microCode.destinationInfo.needSave) {
                MoveValue(dest: vm.microCode.value.value, src: vm.microCode.destinationInfo.register)
                Switch(cell: vm.microCode.value, {
                    SwitchCase(0) {
                        vm.destination.move(to: vm.r0)
                    }
                    SwitchCase(1) {
                        vm.destination.move(to: vm.r1)
                    }
                    SwitchCase(2) {
                        vm.destination.move(to: vm.r2)
                    }
                    SwitchCase(3) {
                        vm.destination.move(to: vm.r3)
                    }
                    SwitchCase(4) {
                        vm.destination.move(to: vm.r4)
                    }
                    SwitchCase(5) {
                        vm.destination.move(to: vm.r5)
                    }
                    SwitchCase(6) { // save in const operand
                    }
                    SwitchCase(7) { //
                        vm.destination.move(to: vm.indexCommand)
                    }
                    SwitchCase(9) { //
                        vm.destination.move(to: vm.stack)
                    }
                    SwitchCase(10) { //
                        vm.fastStack.pushInFront(vm.destination)
                    }
                })
            }
        }
    }

    func microActionPrepareLoadCommand() -> IMacros {
        body {
            vm.indexCommand.copy(to: vm.microCode.memoryAddress)
            vm.indexCommand.inc16()
            vm.microCode.commandStack.push(.commandMemory, .loadCommand)
        }
    }

    func microActionLoadCommand() -> IMacros {
        return body {
            Set(index: vm.microCode.value.value, pool.count)
            SafeLoop(index: vm.microCode.memoryValue.index) {
                vm.microCode.value.ifNotZero {
                    vm.microCode.value.dec()
                }
                Add(index: vm.command.lowCell.value, 1)
                Add(index: vm.microCode.memoryValue.index, -1)
            }
            MoveValue(dest: vm.command.highCell.value, src: vm.microCode.memoryValue.index + 1)
            
            Set(index: vm.microCode.destinationInfo.needLoad, 1)
            FastIf(index: vm.microCode.value.value) {
                Set(index: vm.microCode.destinationInfo.needLoad, 0)
                vm.destination.set(0)
            }
            
            vm.microCode.commandStack.push(.runCommand)
            processingArguments()
        }
    }

    func microActionOperandLoad() -> IMacros {
        body {
            vm.microCode.memoryValue.move(to: vm.operand)
        }
    }

    func microActionDestinationPrepare() -> IMacros {
        body {
            CopyValue(dest: vm.microCode.isPtr, src: vm.microCode.destinationInfo.ptrFlag, tmp: vm.tmp)
            CopyValue(dest: vm.microCode.value.value, src: vm.microCode.destinationInfo.register, tmp: vm.tmp)
            MoveValue(dest: microCode.memorySkip, src: microCode.destinationInfo.needLoad)
            
            vm.microCode.commandStack.push(.loadValue, .loadDestination)
        }
    }

    func microActionDestinationLoad() -> IMacros {
        body {
            vm.microCode.memoryValue.move(to: vm.destination)
        }
    }
    
    func microActionRunCommand() -> IMacros {
        var allCases: [SwitchCase] = []
        for command in pool.commands {
            if command.loadAction == nil {
                allCases.append(
                    SwitchCase(UInt8(command.baseCode - 1),{
                        command.action(vm)
                    })
                )
            }
        }
        return body {
            Switch(cell: vm.command.lowCell, allCases)
        }
    }

    func microActionLoadValue() -> IMacros {
        body {
            Switch(cell: vm.microCode.value, {
                SwitchCase(0) {
                    vm.r0.copy(to: vm.microCode.memoryValue, tmp: vm.tmp)
                }
                SwitchCase(1) {
                    vm.r1.copy(to: vm.microCode.memoryValue, tmp: vm.tmp)
                }
                SwitchCase(2) {
                    vm.r2.copy(to: vm.microCode.memoryValue, tmp: vm.tmp)
                }
                SwitchCase(3) {
                    vm.r3.copy(to: vm.microCode.memoryValue, tmp: vm.tmp)
                }
                SwitchCase(4) {
                    vm.r4.copy(to: vm.microCode.memoryValue, tmp: vm.tmp)
                }
                SwitchCase(5) {
                    vm.r5.copy(to: vm.microCode.memoryValue, tmp: vm.tmp)
                }
                SwitchCase(6) {
                    vm.microCode.commandStack.push(.commandMemory)
                    vm.indexCommand.copy(to: vm.microCode.memoryAddress)
                    vm.indexCommand.inc16()
                }
                SwitchCase(9) {
                    vm.stack.copy(to: vm.microCode.memoryValue)
                }
                SwitchCase(8) {
                    SetZero(vm.microCode.memoryValue.index)
                    SetZero(vm.microCode.memoryValue.index + 1)
                }
                SwitchCase(10) {
                    FastIf(index: vm.microCode.memorySkip) {
                        vm.fastStack.popFromFront(vm.microCode.memoryValue)
                    }
                }
            })
            FastIf(index: vm.microCode.isPtr) {
                vm.microCode.memoryValue.move(to: vm.microCode.memoryAddress)
                FastIf(index: vm.microCode.memorySkip) {
                    vm.microCode.commandStack.push(.commandMemory)
                }
            }
        }
    }
    
    func loadArgument(_ argumentType: Command2ArgumentType, argument: ICommandArgument) -> IMacros {
        body {
            switch argumentType {
            case .register0:
                Set(index: argument.register, 0)
            case .register1:
                Set(index: argument.register, 1)
            case .register2:
                Set(index: argument.register, 2)
            case .register3:
                Set(index: argument.register, 3)
            case .register4:
                Set(index: argument.register, 4)
            case .register5:
                Set(index: argument.register, 5)
            case .none:
                Set(index: argument.needLoad, 0)
                Set(index: argument.register, 8)
            case .ptrRegister0:
                Set(index: argument.ptrFlag, 1)
                Set(index: argument.register, 0)
            case .ptrRegister1:
                Set(index: argument.ptrFlag, 1)
                Set(index: argument.register, 1)
            case .ptrRegister2:
                Set(index: argument.ptrFlag, 1)
                Set(index: argument.register, 2)
            case .ptrRegister3:
                Set(index: argument.ptrFlag, 1)
                Set(index: argument.register, 3)
            case .ptrRegister4:
                Set(index: argument.ptrFlag, 1)
                Set(index: argument.register, 4)
            case .ptrRegister5:
                Set(index: argument.ptrFlag, 1)
                Set(index: argument.register, 5)
            case .registerCS:
                Set(index: argument.register, 9)
            case .const:
                Set(index: argument.register, 6)
            case .registerS0:
                Set(index: argument.register, 10)
            }
        }
    }

    func processingArguments() -> IMacros {
        var allCases: [SwitchCase] = []
        for argument1 in Command2ArgumentType.allCases {
            for argument2 in Command2ArgumentType.allCases {
                let combination = command2ArgumentsCombination(argument1, argument2) >> 8
                allCases.append(SwitchCase(UInt8(combination), {
                    loadArgument(argument1, argument: vm.microCode.destinationInfo)
                    loadArgument(argument2, argument: vm.microCode.operandInfo)
                }))
            }
        }
        return body {
            Set(index: vm.microCode.operandInfo.needLoad, 1)
            
            Set(index: vm.microCode.operandInfo.ptrFlag, 0)
            Set(index: vm.microCode.destinationInfo.ptrFlag, 0)
            
            Switch(cell: vm.command.highCell, allCases)
            vm.destination.set(0)
            vm.microCode.commandStack.push(.prepareDestination)
            vm.operand.set(0)
            FastIf(index: vm.microCode.operandInfo.needLoad) {
                operandPrepare()
            }
        }
    }

    func operandPrepare() -> IMacros {
        body {
            MoveValue(dest: vm.microCode.isPtr, src: vm.microCode.operandInfo.ptrFlag)
            MoveValue(dest: vm.microCode.value.value, src: vm.microCode.operandInfo.register)
            Set(index: vm.microCode.memorySkip, 1)
            
            vm.microCode.commandStack.push(.loadValue, .loadOperand)
        }
    }
}
