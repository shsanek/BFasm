struct Commands {
    let move: Command = Command(name: "mov", actions: [
        .twoArgument(.register, .register, action: { vm, dst, src in src.copy(to: dst) }),
        .twoArgument(.register, .const, action: { vm, dst, src in src.copy(to: dst) }),
        .twoArgument(.register, .memory, action: { vm, dst, src in vm.memory.readValue(address: dst, value: src) }),
        .twoArgument(.memory, .const, action: { vm, dst, src in vm.memory.writeValue(address: dst, value: src) }),
        .twoArgument(.memory, .register, action: { vm, dst, src in vm.memory.writeValue(address: dst, value: src) }),
    ])
    
    let inc: Command = Command(name: "inc", actions: [
        .oneArgument(.register, action: { vm, dst in dst.inc16() })
    ])
    
    let dec: Command = Command(name: "dec", actions: [
        .oneArgument(.register, action: { vm, dst in dst.dec16() })
    ])
    
    let exit: Command = Command(name: "exit", actions: [
        .oneArgument(.const) { vm, reg in
            body {
                CopyValue(dest: vm.flags.errorFlag, src: reg.lowCell.value, tmp: reg.lowCell.zero0)
                Set(index: vm.flags.runFlag, 0)
            }
        }
    ])
    
    let add: Command = Command(name: "add", actions: [
        .twoArgument(.register, .register, action: { vm, dst, scr in dst.add(scr) }),
        .twoArgument(.register, .const, action: { vm, dst, scr in dst.add(scr, saveOperand: false) }),
        .twoArgument(.register, .memory, action: { vm, dst, scr in
            body {
                vm.memory.readValue(address: scr, value: vm.operand)
                dst.add(vm.operand, saveOperand: false)
            }
        })
    ])
    
    let sub: Command = Command(name: "sub", actions: [
        .twoArgument(.register, .register, action: { vm, dst, scr in dst.sub(scr) }),
        .twoArgument(.register, .const, action: { vm, dst, scr in dst.sub(scr, saveOperand: false) }),
        .twoArgument(.register, .memory, action: { vm, dst, scr in
            body {
                vm.memory.readValue(address: scr, value: vm.operand)
                dst.sub(vm.operand, saveOperand: false)
            }
        })
    ])
    
    let mul: Command = Command(name: "mul", actions: [
        .twoArgument(.register, .register, action: { vm, dst, scr in dst.mul(scr, vm: vm) }),
        .twoArgument(.register, .const, action: { vm, dst, scr in dst.mul(scr, vm: vm) }),
        .twoArgument(.register, .memory, action: { vm, dst, scr in
            body {
                vm.memory.readValue(address: scr, value: vm.operand)
                dst.mul(vm.operand, vm: vm)
            }
        })
    ])
    
    let div: Command = Command(name: "div", actions: [
        .twoArgument(.register, .register, action: { vm, dst, scr in
            dst.div(operand: scr, result: dst, mod: vm.tmp0, vm: vm)
        }),
        .twoArgument(.register, .const, action: { vm, dst, scr in
            dst.div(operand: scr, result: dst, mod: vm.tmp0, vm: vm)
        }),
        .twoArgument(.register, .memory, action: { vm, dst, scr in
            body {
                vm.memory.readValue(address: scr, value: vm.operand)
                dst.div(operand: vm.operand, result: dst, mod: vm.tmp0, vm: vm)
            }
        })
    ])
    
    let mod: Command = Command(name: "mod", actions: [
        .twoArgument(.register, .register, action: { vm, dst, scr in
            dst.div(operand: scr, result: vm.tmp0, mod: dst, vm: vm)
        }),
        .twoArgument(.register, .const, action: { vm, dst, scr in
            dst.div(operand: scr, result: vm.tmp0, mod: dst, vm: vm)
        }),
        .twoArgument(.register, .memory, action: { vm, dst, scr in
            body {
                vm.memory.readValue(address: scr, value: vm.operand)
                dst.div(operand: vm.operand, result: vm.tmp0, mod: dst, vm: vm)
            }
        })
    ])
    
    let run: Command = Command(name: "run", specialAction: { vm in
        body {
            Set(index: vm.flags.runFlag, 0)
        }
    })

    let comment = Command(name: "#", specialAction: { vm in
        body {
            ReadNotEndSymbols(vm: vm, reg: vm.tmp1)
        }
    })
}

struct Commands2 {
    let move: Command2 = .init(
        needSaveDestination: true,
        needLoadDestination: false,
        name: "mov",
        action: { vm in vm.operand.move(to: vm.destination) }
    )
    
    let inc: Command2 = .init(
        needSaveDestination: true,
        needLoadDestination: true,
        name: "inc",
        action: { vm in vm.destination.inc16() })
    
    let dec: Command2 = .init(
        needSaveDestination: true,
        needLoadDestination: true,
        name: "dec",
        action: { vm in vm.destination.inc16() })
    
    let exit: Command2 = .init(
        needSaveDestination: false,
        needLoadDestination: true,
        name: "exit",
        action: { vm in
            MoveValue(
                dest: vm.flags.errorFlag,
                src: vm.destination.lowCell.value
            )
            Set(index: vm.flags.runFlag, 0)
        }
    )
    
    let add: Command2 = .init(
        needLoadDestination: true, 
        name: "add",
        action: { vm in vm.destination.add(vm.operand) }
    )
    
    let sub: Command2 = .init(
        needLoadDestination: true,
        name: "sub",
        action: { vm in 
            body {
                vm.flags.resetOverFlag()
                vm.destination.sub(vm.operand, flags: vm.flags)
            }
        }
    )
    
    let mul: Command2 = .init(
        needLoadDestination: true,
        name: "mul",
        action: { vm in vm.destination.mul(vm.operand, vm: vm) }
    )
    
    let div: Command2 = .init(
        needLoadDestination: true,
        name: "div",
        action: { vm in
            body {
                vm.destination.div(operand: vm.operand, result: vm.destination, mod: vm.tmp0, vm: vm)
                vm.fastStack.pushInFront(vm.tmp0)
            }
        }
    )
    
    let cmp: Command2 = .init(
        needSaveDestination: false,
        needLoadDestination: true,
        name: "cmp",
        action: { vm in vm.destination.cmp(vm.operand, vm: vm) }
    )
    
    let mod: Command2 = .init(
        needLoadDestination: true,
        name: "mod",
        action: { vm in 
            body {
                vm.destination.div(operand: vm.operand, result: vm.tmp0, mod: vm.destination, vm: vm)
                vm.fastStack.pushInFront(vm.tmp0)
            }
        }
    )
    
    let jmp: Command2 = .init(
        needSaveDestination: false,
        needLoadDestination: true,
        name: "jmp",
        action: { vm in 
            vm.destination.move(to: vm.indexCommand)
        }
    )
    
    let jne: Command2 = .init(
        needSaveDestination: false,
        needLoadDestination: true,
        name: "j!=",
        action: { vm in
            vm.flags.ifZero {
                emptyBody
            } else: {
                vm.destination.move(to: vm.indexCommand)
            }
        }
    )
    
    let je: Command2 = .init(
        needSaveDestination: false,
        needLoadDestination: true,
        name: "j==",
        action: { vm in
            vm.flags.ifZero {
                vm.destination.move(to: vm.indexCommand)
            }
        }
    )
    
    let jb: Command2 = .init(
        needSaveDestination: false,
        needLoadDestination: true,
        name: "j<",
        action: { vm in
            vm.flags.ifOver {
                vm.destination.move(to: vm.indexCommand)
            } else: {
                emptyBody
            }
        }
    )
    

    let jae: Command2 = .init(
        needSaveDestination: false,
        needLoadDestination: true,
        name: "j=>",
        action: { vm in
            vm.flags.ifOver {
                emptyBody
            } else: {
                vm.destination.move(to: vm.indexCommand)
            }
        }
    )

    let jbe: Command2 = .init(
        needSaveDestination: false,
        needLoadDestination: true,
        name: "j=<",
        action: { vm in
            vm.flags.ifOver {
                vm.destination.move(to: vm.indexCommand)
            } else: {
                vm.flags.ifZero {
                    vm.destination.move(to: vm.indexCommand)
                }
            }
        }
    )
    
    let ja: Command2 = .init(
        needSaveDestination: false,
        needLoadDestination: true,
        name: "j>",
        action: { vm in
            vm.flags.ifOver {
                emptyBody
            } else: {
                vm.flags.ifZero {
                    emptyBody
                } else: {
                    vm.destination.move(to: vm.indexCommand)
                }
            }
        }
    )
    
    let input: Command2 = .init(
        needLoadDestination: false,
        name: "input",
        action: { vm in
            body {
                vm.input.readIfNeededTo(vm.destination.lowCell)
                vm.operand.lowCell.ifZero {
                    vm.input.setNeedNextRead()
                }
            }
        }
    )
    
    let resIn: Command2 = .init(
        needSaveDestination: false,
        needLoadDestination: false,
        name: "resIn",
        action: { vm in
            vm.input.resetNeedNextRead()
        }
    )
    
    let output: Command2 = .init(
        needSaveDestination: false,
        needLoadDestination: true,
        name: "out",
        action: { vm in
            body {
                SetCell(vm.destination.lowCell.value)
                "."
            }
        }
    )
    
    let push: Command2 = .init(
        needSaveDestination: true,
        needLoadDestination: true,
        name: "push",
        action: { vm in
            body {
                vm.stack.inc16()
                Set(index: vm.microCode.destinationInfo.ptrFlag, 1)
                vm.stack.copy(to: vm.microCode.memoryAddress)
            }
        }
    )
    
    let pop: Command2 = .init(
        needSaveDestination: true,
        needLoadDestination: true,
        name: "pop",
        action: { vm in
            body {
                Set(index: vm.microCode.memoryCommand, 0)
                
                vm.stack.copy(to: vm.microCode.memoryAddress)
                vm.stack.dec16()
                
                vm.microCode.commandStack.push(.commandMemory, .loadDestination)
            }
        }
    )
    
    let get: Command2 = .init(
        needSaveDestination: true,
        needLoadDestination: true,
        name: "get",
        action: { vm in
            body {
                Set(index: vm.microCode.memoryCommand, 0)
                
                vm.stack.copy(to: vm.tmp1)
                vm.tmp1.sub(vm.operand, saveOperand: false)
                
                vm.tmp1.move(to: vm.microCode.memoryAddress)
                
                vm.microCode.commandStack.push(.commandMemory, .loadDestination)
            }
        }
    )
    
    let call: Command2 = .init(
        needSaveDestination: false,
        needLoadDestination: true,
        name: "call",
        action: { vm in
            body {
                vm.stack.inc16()
                
                Set(index: vm.microCode.memoryCommand, 1)
                vm.stack.copy(to: vm.microCode.memoryAddress)
                vm.indexCommand.copy(to: vm.microCode.memoryValue)
                
                vm.destination.move(to: vm.indexCommand)

                vm.microCode.commandStack.push(.commandMemory)
            }
        }
    )
    
    let ret: Command2 = .init(
        needSaveDestination: true,
        needLoadDestination: true,
        name: "ret",
        action: { vm in
            body {
                Set(index: vm.microCode.memoryCommand, 0)
                
                vm.stack.copy(to: vm.microCode.memoryAddress)
                vm.stack.dec16()
                vm.stack.sub(vm.destination)

                Set(index: vm.microCode.destinationInfo.register, 7)
                Set(index: vm.microCode.destinationInfo.ptrFlag, 0)

                vm.microCode.commandStack.push(.commandMemory, .loadDestination)
            }
        }
    )
    
    let fPush: Command2 = .init(
        needSaveDestination: false,
        needLoadDestination: true,
        name: "fPush",
        action: { vm in
            vm.fastStack.pushInFront(vm.destination)
        }
    )
    
    let bPush: Command2 = .init(
        needSaveDestination: false,
        needLoadDestination: true,
        name: "bPush",
        action: { vm in
            vm.fastStack.pushInBack(vm.destination)
        }
    )
    
    let fPop: Command2 = .init(
        needLoadDestination: false,
        name: "fPop",
        action: { vm in
            vm.fastStack.popFromFront(vm.destination)
        }
    )
    
    let bPop: Command2 = .init(
        needLoadDestination: false,
        name: "bPop",
        action: { vm in
            vm.fastStack.popFromBack(vm.destination)
        }
    )
    
    let run: Command2 = .init(name: "run", loadAction: { vm in
        body {
            Set(index: vm.flags.runFlag, 0)
        }
    })

    let comment: Command2 = .init(name: "#", loadAction: { vm in
        body {
            ReadNotEndSymbols(vm: vm, reg: vm.tmp1)
        }
    })
}
