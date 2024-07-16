extension Array where Element == UInt8 {
    func register16Value(_ register: BigRegister16) -> UInt16 {
        let byte0 = self[register.lowCell.index]
        let byte1 = self[register.highCell.index]
        return UInt16(Int(byte0) + Int(byte1) * 256)
    }
    
    mutating func setRegister16Value(_ register: BigRegister16, value: UInt16) {
        self[register.lowCell.index] = UInt8(value % 256)
        self[register.highCell.index] = UInt8(value / 256)
    }
    
    func checkRegister16Value(_ register: BigRegister16, value: UInt16) -> Bool {
        guard register16Value(register) == value else {
            return false
        }
        return checkFastCell(register.highCell) && checkFastCell(register.lowCell)
    }
    
    func checkFastCell(_ cell: Right4ByteFastZeroIfCell) -> Bool {
        return
            self[cell.index + 1] == 0 &&
            self[cell.index - 1] == 0 &&
            self[cell.index - 2] == 1
    }
    
    func checkFastCell(_ cell: Left4ByteFastZeroIfCell) -> Bool {
        return
            self[cell.index - 1] == 0 &&
            self[cell.index + 1] == 0 &&
            self[cell.index + 2] == 1
    }
    
    func getMemoryCell(_ vm: VirtualMachine = VirtualMachine(), index: Int) -> MemoryCell {
        let index = MemoryCell.size * index + vm.memory.firstCell.index
        return .init(firstByte: index)
    }
    
    func getValue(_ cell: Data2ByteCell) -> UInt16 {
        let byte0 = self[cell.index]
        let byte1 = self[cell.index + 1]
        return UInt16(Int(byte0) + Int(byte1) * 256)
    }
    
    func dump(_ vm: VirtualMachine) -> [UInt16] {
        var index = vm.memory.firstCell.index
        var dump: [UInt16] = []
        while index + MemoryCell.size < self.count {
            let cell = MemoryCell(firstByte: index)
            index += MemoryCell.size
            dump.append(self.getValue(cell.data))
        }
        return dump
    }
    
    mutating func validMemory(_ vm: VirtualMachine) -> Bool {
        var index = vm.memory.firstCell.index
        var result = true
        while index + MemoryCell.size < self.count {
            let cell = MemoryCell(firstByte: index)
            index += MemoryCell.size
            result = result && (self[cell.flags.lowValue] == 0)
            result = result && (self[cell.flags.highValue] == 0)
        
            result = result && (self[cell.commandFlag] == 0)
        
            result = result && (self[cell.address.lowValue] == 0)
            result = result && (self[cell.address.highValue] == 0)
            
            result = result && (self[cell.moveData.lowValue] == 0)
            result = result && (self[cell.moveData.highValue] == 0)

            result = result && (cell.moveData.value(&self) == 0)
            if !result {
                print((index - vm.memory.firstCell.index) / MemoryCell.size)
                break
            }
        }
        return result
    }
    
    mutating func fastStack(_ vm: VirtualMachine) -> [Int] {
        return vm.fastStack.elements.map { cell in
            cell.value(&self)
        }
    }
    
    mutating func setValue(_ cell: Data2ByteCell, value: UInt16) {
        self[cell.index] = UInt8(value % 256)
        self[cell.index + 1] = UInt8(value / 256)
    }
}

class MemoryContainer {
    var memory: [UInt8]
    
    init(_ count: Int) {
        self.memory = .init(repeating: 0, count: count)
    }
}
