struct MemoryCell {
    let index: Int
    
    init(firstByte: Int) {
        self.index = firstByte
        self.backFlagIndex = firstByte
        self.nextFlagIndex = firstByte + 1
        self.address = .init(firstByte: index + 2)
        self.moveData = .init(firstByte: index + 2 + BigRegister16.size)
        self.data = .init(firstByte: index + 2 + BigRegister16.size + Data2ByteCell.size)
        self.commandFlag = self.data.index + 2
    }

    static let size = 3 + BigRegister16.size + Data2ByteCell.size + Data2ByteCell.size

    let backFlagIndex: Int
    let nextFlagIndex: Int

    let commandFlag: Int

    let address: BigRegister16
    let moveData: Data2ByteCell
    let data: Data2ByteCell
}
