struct CommandArgumentReader: IMacros {
    let vm: VirtualMachine
    let errorAction: IMacros
    
    init(vm: VirtualMachine, @MacrosBuilder _ errorAction: () -> IMacros) {
        self.vm = vm
        self.errorAction = errorAction()
    }

    func generateCode(manager: SelectedCellManager) -> String {
        body {
            Set(index: vm.tmp3.lowCell.zero0, 0)
            Set(index: vm.tmp3.lowCell.zero1, 0)
            parseArgument0()
            vm.memory.writeValue(address: vm.indexCommand, value: vm.command)
            vm.indexCommand.inc16()
            FastIf(index: vm.tmp3.lowCell.zero1) { // const
                vm.input.resetNeedNextRead()
                ReadInt16(vm: vm, reg: vm.operand)
                vm.memory.writeValue(address: vm.indexCommand, value: vm.operand)
                vm.indexCommand.inc16()
            }
            end()
            FastIf(index: vm.tmp3.lowCell.zero0) { // error
                errorAction
            }
        }.generateCode(manager: manager)
    }
    
    func checkShift(manager: SelectedCellManager) -> Int? {
        return nil
    }
    
    private func indexForRegister(regIndex0: Int?, regIndex1: Int?) -> UInt8 {
        if let regIndex0 {
            if let regIndex1 {
                if regIndex0 == 0 {
                    if regIndex1 == 1 {
                        return 0
                    } else if regIndex1 == 2 {
                        return 1
                    }
                } else if regIndex0 == 1 {
                    if regIndex1 == 0 {
                        return 2
                    } else if regIndex1 == 2 {
                        return 3
                    }
                } else if regIndex0 == 2 {
                    if regIndex1 == 0 {
                        return 4
                    } else if regIndex1 == 1 {
                        return 5
                    }
                }
                assert(false)
            } else {
                if regIndex0 == 0 {
                    return 0
                } else if regIndex0 == 1 {
                    return 1
                } else if regIndex0 == 2 {
                    return 2
                }
                assert(false)
            }
        }
        return 0
    }
    
    private func parseArgument0() -> IMacros {
        var result = [StringSwitchCase]()
        if allCommandArgumentPatterns.contains(where: { $0.combination.argument1 == .register }) {
            result.append(contentsOf: getRegisterParse { index in
                body {
                    parseArgument1(type: .register, reg0: index)
                }
            })
        }
        if allCommandArgumentPatterns.contains(where: { $0.combination.argument1 == .memory }) {
            result.append(contentsOf: getPtr { index in
                body {
                    parseArgument1(type: .memory, reg0: index)
                }
            })
        }
        if let pattern = allCommandArgumentPatterns.first(where: { $0.combination.argument1 == .const }) {
            let all = allCommandArgumentPatterns.filter({ $0.combination.argument1 == .const })
            assert(all.count == 1 && all[0].combination.argument2 == nil)
            result.append(contentsOf: getConst {
                body {
                    vm.command.addConst(UInt8(pattern.baseShift))
                }
            })
        }
        if let pattern = allCommandArgumentPatterns.first(where: { $0.combination.argument1 == .none }) {
            result.append(contentsOf: getEnd {
                body {
                    vm.command.addConst(UInt8(pattern.baseShift))
                }
            })
        }
        return ReadStringSwitch(vm: vm, result) {
            Set(index: vm.tmp3.lowCell.zero0, 1)
        }
    }

    private func parseArgument1(type: CommandArgumentType, reg0: Int?) -> IMacros {
        var result = [StringSwitchCase]()
        if let pattern = allCommandArgumentPatterns.first(where: { $0.combination == .init(argument1: type, argument2: .register) }) {
            result.append(contentsOf: getRegisterParse(filter: reg0) { index in
                body {
                    vm.command.addConst(indexForRegister(regIndex0: reg0, regIndex1: index) + UInt8(pattern.baseShift))
                }
            })
        }
        if let pattern = allCommandArgumentPatterns.first(where: { $0.combination == .init(argument1: type, argument2: .memory) }) {
            result.append(contentsOf: getPtr(filter: reg0) { index in
                body {
                    vm.command.addConst(indexForRegister(regIndex0: reg0, regIndex1: index) + UInt8(pattern.baseShift))
                }
            })
        }
        if let pattern = allCommandArgumentPatterns.first(where: { $0.combination == .init(argument1: type, argument2: .const) }) {
            result.append(contentsOf: getConst {
                body {
                    vm.command.addConst(indexForRegister(regIndex0: reg0, regIndex1: nil) + UInt8(pattern.baseShift))
                }
            })
        }
        if let pattern = allCommandArgumentPatterns.first(where: { $0.combination == .init(argument1: type, argument2: .none) }) {
            result.append(contentsOf: getEnd {
                body {
                    vm.command.addConst(indexForRegister(regIndex0: reg0, regIndex1: nil) + UInt8(pattern.baseShift))
                }
            })
        }
        return ReadStringSwitch(vm: vm, result) {
            Set(index: vm.tmp3.lowCell.zero0, 1)
        }
    }
    
    fileprivate func end() -> IMacros {
        ReadStringSwitch(vm: vm) {
            StringSwitchCase(";") {
            }
            StringSwitchCase() {
                Set(index: vm.tmp3.lowCell.zero0, 1)
            }
        }
    }
    
    private func getEnd(_ action: () -> IMacros) -> [StringSwitchCase] {
        [StringSwitchCase(";") {
            vm.input.resetNeedNextRead()
            
            action()
        }]
    }
    
    private func getConst(_ action: () -> IMacros) -> [StringSwitchCase] {
        return (0...9).map { i in
            StringSwitchCase("\(i)") {
                Set(index: vm.tmp3.lowCell.zero1, 1)
                action()
            }
        }
    }
    
    private func getPtr(filter: Int? = nil, _ action: (Int) -> IMacros) -> [StringSwitchCase] {
        [
            StringSwitchCase("ptr") {
                ReadStringSwitch(vm: vm, getRegisterParse(filter: filter, action)) {
                    Set(index: vm.tmp3.lowCell.zero0, 1)
                }
            }
        ]
    }
    
    private func getRegisterParse(filter: Int? = nil, _ action: (Int) -> IMacros) -> [StringSwitchCase] {
        var cases: [StringSwitchCase] = []
        if filter != 0 {
            cases.append(StringSwitchCase("r0") {
                action(0)
            })
        }
        if filter != 1 {
            cases.append(StringSwitchCase("r1") {
                action(1)
            })
        }
        if filter != 2 {
            cases.append(StringSwitchCase("r2") {
                action(2)
            })
        }
        return cases
    }
    
}


class Command2 {
    var baseCode: Int = 0

    let needSaveDestination: Bool
    let needLoadDestination: Bool

    let name: String
    
    let action: ((VirtualMachine) -> IMacros)
    let loadAction: ((VirtualMachine) -> IMacros)?
    
    init(
        needSaveDestination: Bool = true,
        needLoadDestination: Bool,
        name: String,
        @MacrosBuilder action: @escaping (VirtualMachine) -> IMacros
    ) {
        self.needSaveDestination = needSaveDestination
        self.needLoadDestination = needLoadDestination
        self.name = name
        self.action = needSaveDestination ? { vm in
            body { 
                vm.microCode.commandStack.push(.saveDestination)
                action(vm)
//                CustomBreakPoint { memory, currentPoint in
//                    print("run command \(name)")
//                }
            }
        } : { vm in
            body {
                action(vm)
//                CustomBreakPoint { memory, currentPoint in
//                    print("run command \(name)")
//                }
            }
        }
        self.loadAction = nil
    }
    
    init(
        name: String,
        @MacrosBuilder loadAction: @escaping (VirtualMachine) -> IMacros
    ) {
        self.needSaveDestination = false
        self.needLoadDestination = false
        self.name = name
        self.action = { _ in emptyBody }
        self.loadAction = loadAction
    }

    func load(_ vm: VirtualMachine) -> IMacros {
        if let loadAction {
            return loadAction(vm)
        }
        return body {
            vm.command.set(UInt16(baseCode))
        }
    }
    
    var sortNumber: Int {
        var result = 0
        if needLoadDestination {
            result += 1
        }
        return result
    }
}

enum Command2ArgumentType: UInt8, CaseIterable {
    case register0
    case register1
    case register2
    case register3
    case register4
    case register5
    case registerCS
    case registerS0
    
    case none

    case ptrRegister0
    case ptrRegister1
    case ptrRegister2
    case ptrRegister3
    case ptrRegister4
    case ptrRegister5
    
    case const
}

struct Command2ArgumentReader {
    let vm: VirtualMachine
    let errorAction: IMacros
    
    let needLoadRegisterNumberFlag: Int = 0
    let needLoadRegisterConstFlag: Int = 1
    let needSaveConstFlag: Int = 3
    let endCommandFlag: Int = 4
    let errorFlag: Int = 5

    init(vm: VirtualMachine, @MacrosBuilder _ errorAction: () -> IMacros) {
        self.vm = vm
        self.errorAction = errorAction()
    }
    
    func reset() -> IMacros {
        body {
            
        }
    }
    
    func parseArgument() -> IMacros {
        body {
            Set(index: endCommandFlag, 2)
            Set(index: needSaveConstFlag, 0)
            Set(index: errorFlag, 0)
            vm.command.lowCell.move(to: vm.tmp3.lowCell)
            SafeLoop(index: endCommandFlag) {
                Add(index: endCommandFlag, -1)
                vm.command.mul(UInt8(Command2ArgumentType.allCases.count), inline: false)
                Set(index: needLoadRegisterNumberFlag, 1)
                Set(index: needLoadRegisterConstFlag, 0)
                ReadStringSwitch(vm: vm, getEnd() + getConst() + getPtr()) {
                    vm.input.resetNeedNextRead()
                }
                FastIf(index: needLoadRegisterConstFlag) {
                    vm.input.resetNeedNextRead()
                    ReadInt16(vm: vm, reg: vm.operand)
                    Set(index: needSaveConstFlag, 1)
                }
                FastIf(index: needLoadRegisterNumberFlag) {
                    ReadStringSwitch(vm: vm, getRegisterParse()) {
                        Set(index: endCommandFlag, 0)
                        Set(index: errorFlag, 1)
                    }
                }
            }
            Set(index: endCommandFlag, 1)
            vm.command.highCell.ifNotZero {
                Set(index: errorFlag, 1)
            }
            FastIf(index: errorFlag) {
                Set(index: vm.flags.errorFlag, 1)
                Set(index: vm.flags.runFlag, 0)
                Set(index: endCommandFlag, 0)
                errorAction
            }
            FastIf(index: endCommandFlag) {
                end()
                vm.command.lowCell.move(to: vm.command.highCell)
                vm.tmp3.lowCell.move(to: vm.command.lowCell)
                Add(index: needSaveConstFlag, 1)
                SafeLoop(index: needSaveConstFlag) {
                    vm.memory.writeValue(address: vm.indexCommand, value: vm.command)
                    vm.indexCommand.inc16()
                    vm.operand.move(to: vm.command)
                    Add(index: needSaveConstFlag, -1)
                }
            }
        }
    }
    
    fileprivate func end() -> IMacros {
        ReadStringSwitch(vm: vm) {
            StringSwitchCase(";") {
            }
            StringSwitchCase() {
                Set(index: endCommandFlag, 0)
            }
        }
    }
    
    private func getEnd() -> [StringSwitchCase] {
        [StringSwitchCase(";") {
            Set(index: needLoadRegisterNumberFlag, 0)
            Add(index: vm.command.lowCell.value, Int(Command2ArgumentType.none.rawValue))
            vm.input.resetNeedNextRead()
        }]
    }
    
    private func getConst() -> [StringSwitchCase] {
        return (0...9).map { i in
            StringSwitchCase("\(i)") {
                Set(index: needLoadRegisterConstFlag, 1)
                Set(index: needLoadRegisterNumberFlag, 0)
                Add(index: vm.command.lowCell.value, Int(Command2ArgumentType.const.rawValue))
            }
        }
    }
    
    private func getPtr() -> [StringSwitchCase] {
        [
            StringSwitchCase("ptr") {
                Add(index: vm.command.lowCell.value, Int(Command2ArgumentType.ptrRegister0.rawValue))
            }
        ] + [
            StringSwitchCase("s0") {
                Set(index: needLoadRegisterNumberFlag, 0)
                Add(index: vm.command.lowCell.value, Int(Command2ArgumentType.registerS0.rawValue))
            }
        ] + [
            StringSwitchCase("cs") {
                Set(index: needLoadRegisterNumberFlag, 0)
                Add(index: vm.command.lowCell.value, Int(Command2ArgumentType.registerCS.rawValue))
            }
        ]
    }
    
    private func getRegisterParse() -> [StringSwitchCase] {
        return (0...5).map { index in
            StringSwitchCase("r\(index)") {
                Add(index: vm.command.lowCell.value, index)
            }
        }
    }
}


func command2ArgumentsCombination(_ a: Command2ArgumentType, _ b: Command2ArgumentType) -> Int {
    return (Int(a.rawValue) * Command2ArgumentType.allCases.count + Int(b.rawValue)) << 8
}
