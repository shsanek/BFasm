func ReadAllSymbols(vm: VirtualMachine, reg: BigRegister16) -> IMacros {
    body {
        Set(index: reg.highCell.zero1, 1)
        SafeLoop(index: reg.highCell.zero1) {
            vm.input.readIfNeededTo(vm.tmp0.lowCell)
            Switch(cell: vm.tmp0.lowCell) {
                SwitchCase(" ") {
                    vm.input.setNeedNextRead()
                }
                SwitchCase("\t") {
                    vm.input.setNeedNextRead()
                }
                SwitchCase("\n") {
                    vm.input.setNeedNextRead()
                }
                SwitchCase(",") {
                    vm.input.setNeedNextRead()
                }
                SwitchCase {
                    Set(index: reg.highCell.zero1, 0)
                }
            }
        }
    }
}

func ReadNotEndSymbols(vm: VirtualMachine, reg: BigRegister16) -> IMacros {
    body {
        Set(index: reg.highCell.zero1, 1)
        SafeLoop(index: reg.highCell.zero1) {
            vm.input.readIfNeededTo(vm.tmp0.lowCell)
            Switch(cell: vm.tmp0.lowCell) {
                SwitchCase(";") {
                    vm.input.setNeedNextRead()
                    Set(index: reg.highCell.zero1, 0)
                }
                SwitchCase {
                    vm.input.setNeedNextRead()
                }
            }
        }
    }
}

func ReadInt16(vm: VirtualMachine, reg: BigRegister16) -> IMacros {
    let cases = (0...9).map({ i in
        SwitchCase("\(i)") {
            Set(index: reg.highCell.zero1, 0)
            reg.mul(10)
            reg.addConst(UInt8(i))
            vm.input.setNeedNextRead()
            Set(index: reg.highCell.zero1, 1)
        }
    })

    return body {
        reg.set(0)
        ReadAllSymbols(vm: vm, reg: reg)
        Set(index: reg.highCell.zero1, 1)
        SafeLoop(index: reg.highCell.zero1) {
            vm.input.readIfNeededTo(vm.tmp0.lowCell)
            Switch(cell: vm.tmp0.lowCell, cases) {
                Set(index: reg.highCell.zero1, 0)
            }
        }
    }
}
