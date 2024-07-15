
struct BigRegister16 {
    let index: Int
    
    let lowCell: Left4ByteFastZeroIfCell
    let highCell: Right4ByteFastZeroIfCell
    
    static let size: Int = 7
    
    init(firstByte: Int) {
        self.index = firstByte
        lowCell = .init(firstByte: firstByte)
        highCell = .init(firstByte: firstByte + 3)
    }
    
    func initMemory() -> IMacros {
        body {
            lowCell.initMemory()
            highCell.initMemory()
        }
    }
    
    func inc16() -> IMacros {
        body {
            lowCell.inc()
            lowCell.ifZero {
                highCell.inc()
            }
        }
    }
    
    func dec16() -> IMacros {
        body {
            lowCell.ifZero {
                highCell.dec()
            }
            lowCell.dec()
        }
    }
    
    func set(_ value: UInt16) -> IMacros {
        body {
            Set(index: lowCell.value, Int(value % 256))
            Set(index: highCell.value, Int(value / 256))
        }
    }
    
    func move(to dst: BigRegister16) -> IMacros {
        assert(index != dst.index)
        return body {
            MoveValue(dest: dst.lowCell.index, src: lowCell.index)
            MoveValue(dest: dst.highCell.index, src: highCell.index)
        }
    }
    
    func move(to dst: Data2ByteCell) -> IMacros {
        assert(index != dst.index)
        return body {
            MoveValue(dest: dst.index, src: lowCell.index)
            MoveValue(dest: dst.index + 1, src: highCell.index)
        }
    }
    
    func copy(to dst: BigRegister16) -> IMacros {
        return body {
            CopyValue(dest: dst.lowCell.index, src: lowCell.index, tmp: index - 1)
            CopyValue(dest: dst.highCell.index, src: highCell.index, tmp: index - 1)
        }
    }
    
    func copy(to dst: Data2ByteCell) -> IMacros {
        body {
            CopyValue(dest: dst.index, src: lowCell.index, tmp: lowCell.index - 1)
            CopyValue(dest: dst.index + 1, src: highCell.index, tmp: lowCell.index - 1)
        }
    }
    
    func safeDec16() -> IMacros {
        body {
            lowCell.if {
                lowCell.dec()
            } zero: {
                highCell.ifNotZero {
                    lowCell.dec()
                    highCell.dec()
                }
            }
        }
    }
    
    func safeDec16(
        @MacrosBuilder zero: () -> IMacros,
        @MacrosBuilder notZero: () -> IMacros
    ) -> IMacros {
        body {
            lowCell.if {
                lowCell.dec()
                notZero()
            } zero: {
                highCell.if(notZero: {
                    lowCell.dec()
                    highCell.dec()
                    notZero()
                }, zero: {
                    zero()
                })
            }
        }
    }
    
    func sub(_ reg: BigRegister16, saveOperand: Bool = true, flags: RegisterFlags? = nil) -> IMacros {
        assert(index != reg.index)
        return body {
            SafeLoop(index: reg.lowCell.value) {
                lowCell.ifZero {
                    Set(index: highCell.zero0, 1)
                }
                lowCell.dec()
                if saveOperand {
                    Add(index: reg.lowCell.zero0, 1) // save for reset
                }
                reg.lowCell.dec()
            }
            SafeLoop(index: highCell.zero0) {
                Set(index: highCell.zero0, 0)
                if let flags {
                    highCell.ifZero {
                        flags.setOverFlag()
                    }
                }
                highCell.dec()
            }
            SafeLoop(index: reg.highCell.value) {
                if saveOperand {
                    Add(index: reg.highCell.zero0, 1)
                }
                reg.highCell.dec()
                if let flags {
                    highCell.ifZero {
                        flags.setOverFlag()
                    }
                }
                highCell.dec()
            }
            if let flags {
                highCell.ifZero {
                    lowCell.ifZero {
                        flags.setZeroFlag()
                    }
                }
            }
            if saveOperand {
                SafeLoop(index: reg.highCell.zero0) {
                    reg.highCell.inc()
                    Add(index: reg.highCell.zero0, -1)
                }
                SafeLoop(index: reg.lowCell.zero0) {
                    reg.lowCell.inc()
                    Add(index: reg.lowCell.zero0, -1)
                }
            }
        }
    }
    
    func add(_ reg: BigRegister16, saveOperand: Bool = true, flags: RegisterFlags? = nil) -> IMacros {
        assert(index != reg.index)
        return body {
            SafeLoop(index: reg.lowCell.value) {
                lowCell.inc()
                lowCell.ifZero {
                    Set(index: highCell.zero0, 1)
                }
                if saveOperand {
                    Add(index: reg.lowCell.zero0, 1) // save for reset
                }
                reg.lowCell.dec()
            }
            SafeLoop(index: highCell.zero0) {
                highCell.inc()
                Set(index: highCell.zero0, 0)
                if let flags {
                    highCell.ifZero {
                        flags.setOverFlag()
                    }
                }
            }
            SafeLoop(index: reg.highCell.value) {
                highCell.inc()
                if saveOperand {
                    Add(index: reg.highCell.zero0, 1) // save for reset
                }
                reg.highCell.dec()
                if let flags {
                    highCell.ifZero {
                        flags.setOverFlag()
                    }
                }
            }
            if saveOperand {
                SafeLoop(index: reg.highCell.zero0) {
                    reg.highCell.inc()
                    Add(index: reg.highCell.zero0, -1)
                }
                SafeLoop(index: reg.lowCell.zero0) {
                    reg.lowCell.inc()
                    Add(index: reg.lowCell.zero0, -1)
                }
            }
        }
    }
    
    func addConst(_ const: UInt8) -> IMacros {
        if const == 0 {
            return emptyBody
        }
        return body {
            Set(index: highCell.zero1, Int(const))
            SafeLoop(index: highCell.zero1) {
                lowCell.inc()
                lowCell.ifZero {
                    Set(index: highCell.zero0, 1)
                }
                Add(index: highCell.zero1, -1)
            }
            SafeLoop(index: highCell.zero0) {
                highCell.inc()
                Set(index: highCell.zero0, 0)
//                highCell.ifZero {
//                    lowCell.inc()
//                }
            }
         }
    }
    
    func mul(_ const: UInt8, inline: Bool = true) -> IMacros {
        if const == 0 {
            return body {
                SetZero(lowCell.value)
                SetZero(highCell.value)
            }
        }
        let incLow = body {
            lowCell.inc()
            lowCell.ifZero {
                Add(index: highCell.zero1, 1)
            }
        }
        let incHigh = body {
            highCell.inc()
        }
        let loop = { (one: Int, action: IMacros) -> IMacros in
            body {
                if inline {
                    ConstLoop(count: Int(const - 1)) {
                        action
                    }
                } else {
                    Set(index: one, Int(const - 1))
                    SafeLoop(index: one) {
                        action
                        Add(index: one, -1)
                    }
                    Set(index: one, 1)
                }
            }
        }
        return body {
            CopyValue(dest: highCell.zero0, src: lowCell.value, tmp: lowCell.zero1)
            SafeLoop(index: highCell.zero0) {
                loop(highCell.one0, incLow)
                Add(index: highCell.zero0, -1)
            }
            MoveValue(dest: lowCell.zero1, src: highCell.zero1)
            CopyValue(dest: lowCell.zero0, src: highCell.value, tmp: highCell.zero1)
            SafeLoop(index: lowCell.zero0) {
                loop(lowCell.one0, incHigh)
                Add(index: lowCell.zero0, -1)
            }
            SafeLoop(index: lowCell.zero1) {
                incHigh
                Add(index: lowCell.zero1, -1)
            }
        }
    }
    
    func shiftToTop(flags: RegisterFlags? = nil) -> IMacros {
        body {
            if let flags {
                highCell.ifNotZero {
                    flags.setOverFlag()
                }
            }
            lowCell.move(to: highCell)
        }
    }
    
    func mul(_ reg: BigRegister16, vm: VirtualMachine) -> IMacros {
        body {
            copy(to: vm.tmp2)
            vm.flags.resetOverFlag()
            mul(reg.lowCell, flags: vm.flags)
            reg.highCell.ifNotZero {
                vm.tmp2.hightFatsMul(reg.highCell, flags: vm.flags)
                add(vm.tmp2, saveOperand: false, flags: vm.flags)
            }
        }
    }
    
    private func hightFatsMul(_ cell: Right4ByteFastZeroIfCell, flags: RegisterFlags? = nil) -> IMacros {
        let incHigh = body {
            highCell.inc()
            if let flags {
                highCell.ifZero {
                    flags.setOverFlag()
                }
            }
        }
        let loop = { (action: IMacros) -> IMacros in
            body {
                SafeLoop(index: cell.value) {
                    action
                    Add(index: cell.zero0, 1)
                    Add(index: cell.value, -1)
                }
                MoveValue(dest: cell.value, src: cell.zero0)
            }
        }
        return body {
            if let flags {
                highCell.ifNotZero({
                    flags.setOverFlag()
                })
            }
            SetZero(highCell.value)
            SafeLoop(index: lowCell.value) {
                loop(incHigh)
                Add(index: lowCell.value, -1)
            }
        }
    }
    
    func mul(_ cell: I3ByteCell, flags: RegisterFlags? = nil) -> IMacros {
        let incLow = body {
            lowCell.inc()
            lowCell.ifZero {
                Add(index: highCell.zero1, 1)
            }
        }
        let incHigh = body {
            highCell.inc()
            if let flags {
                highCell.ifZero {
                    flags.setOverFlag()
                }
            }
        }
        let loop = { (action: IMacros) -> IMacros in
            body {
                SafeLoop(index: cell.value) {
                    action
                    Add(index: cell.zero0, 1)
                    Add(index: cell.value, -1)
                }
                MoveValue(dest: cell.value, src: cell.zero0)
            }
        }
        return body {
            MoveValue(dest: highCell.zero0, src: lowCell.value)
            SafeLoop(index: highCell.zero0) {
                loop(incLow)
                Add(index: highCell.zero0, -1)
            }
            MoveValue(dest: lowCell.zero1, src: highCell.zero1)
            MoveValue(dest: lowCell.zero0, src: highCell.value)
            SafeLoop(index: lowCell.zero0) {
                loop(incHigh)
                Add(index: lowCell.zero0, -1)
            }
            SafeLoop(index: lowCell.zero1) {
                incHigh
                Add(index: lowCell.zero1, -1)
            }
        }
    }
    
    func subConst(_ const: UInt8, flags: RegisterFlags? = nil) -> IMacros {
        if const == 0 {
            return emptyBody
        }
        return body {
            Set(index: highCell.zero1, Int(const))
            SafeLoop(index: highCell.zero1) {
                lowCell.ifZero {
                    Set(index: highCell.zero0, 1)
                }
                lowCell.dec()
                Add(index: highCell.zero1, -1)
            }
            SafeLoop(index: highCell.zero0) {
                Set(index: highCell.zero0, 0)
                if let flags {
                    highCell.ifZero {
                        flags.setOverFlag()
                    }
                }
                highCell.dec()
            }
         }
    }
    
    func divConst(
        _ const: UInt8,
        result: BigRegister16,
        mod: BigRegister16,
        vm: VirtualMachine
    ) -> IMacros {
        if const == 0 || const == 1 {
            return body {
                copy(to: result)
                mod.set(0)
            }
        }
        return body {
            copy(to: vm.tmp2)
            result.set(0)
            Set(index: vm.flags.runFlag, 1)
            SafeLoop(index: vm.flags.runFlag) {
                vm.tmp2.copy(to: mod)
                vm.flags.resetOverFlag()
                vm.tmp2.subConst(const, flags: vm.flags)
                vm.flags.ifOver {
                    Set(index: vm.flags.runFlag, 0)
                } else: {
                    result.inc16()
                }
                Set(result.index)
            }
            Set(index: vm.flags.runFlag, 1)
        }
    }
    
    func cmp(_ reg: BigRegister16, saveOperand: Bool = true, vm: VirtualMachine) -> IMacros {
        assert(index != reg.index)
        return body {
            vm.flags.resetOverFlag()
            SafeLoop(index: reg.highCell.value) {
                if saveOperand {
                    Add(index: reg.lowCell.zero0, 1)
                    Add(index: reg.lowCell.zero1, 1)
                }
                reg.highCell.dec()
            
                highCell.if(notZero: {
                    highCell.dec()
                }, zero: {
                    vm.flags.setOverFlag()
                    Add(index: reg.lowCell.zero1, -1)
                    SafeLoop(index: reg.highCell.value) {
                        if saveOperand {
                            Add(index: reg.lowCell.zero0, 1)
                        }
                        reg.highCell.dec()
                    }
                })
            }
            vm.flags.ifOver(save: false) {
                emptyBody
            } else: {
                vm.flags.resetOverFlag()
                highCell.ifZero {
                    Set(index: vm.flags.zeroFlag, 1)
                    SafeLoop(index: reg.lowCell.value) {
                        if saveOperand {
                            Add(index: reg.highCell.zero0, 1)
                            Add(index: reg.highCell.zero1, 1)
                        }
                        reg.lowCell.dec()
                        
                        lowCell.if(notZero: {
                            lowCell.dec()
                        }, zero: {
                            Set(index: vm.flags.zeroFlag, 0)
                            vm.flags.setOverFlag()
                            Add(index: reg.highCell.zero1, -1)

                            SafeLoop(index: reg.lowCell.value) {
                                if saveOperand {
                                    Add(index: reg.highCell.zero0, 1)
                                }
                                reg.lowCell.dec()
                            }
                        })
                    }
                    lowCell.ifNotZero {
                        Set(index: vm.flags.zeroFlag, 0)
                    }
                    if saveOperand {
                        SafeLoop(index: reg.highCell.zero0) {
                            reg.lowCell.inc()
                            Add(index: reg.highCell.zero0, -1)
                        }
                        SafeLoop(index: reg.highCell.zero1) {
                            lowCell.inc()
                            Add(index: reg.highCell.zero1, -1)
                        }
                    }
                }
            }
            if saveOperand {
                SafeLoop(index: reg.lowCell.zero0) {
                    reg.highCell.inc()
                    Add(index: reg.lowCell.zero0, -1)
                }
                SafeLoop(index: reg.lowCell.zero1) {
                    highCell.inc()
                    Add(index: reg.lowCell.zero1, -1)
                }
            }
        }
    }
    
    func div(
        operand: BigRegister16,
        result: BigRegister16,
        mod: BigRegister16,
        vm: VirtualMachine
    ) -> IMacros {
        body {
            copy(to: mod)
            result.set(0)
            vm.table2_n.startFullList()
            operand.highCell.ifNotZero {
                vm.table2_n.startShortList()
            }
            mod.highCell.ifZero {
                vm.table2_n.startShortList()
            }
            vm.table2_n.runLoop(workRegister: vm.tmp1) { value, stop in
                body {
                    vm.flags.resetOverFlag()
                    vm.tmp1.mul(operand, vm: vm)
                    vm.flags.ifOver {
                        emptyBody
                    } else: {
                        mod.cmp(vm.tmp1, saveOperand: true, vm: vm)
                        vm.flags.ifOver {
                        } else: {
                            mod.sub(vm.tmp1, saveOperand: false)
                            result.add(value, saveOperand: true)
                        }
                    }
                }
            }
        }
    }
}
