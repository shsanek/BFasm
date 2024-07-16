struct MemoryCell {
    let index: Int
    
    init(firstByte: Int) {
        self.index = firstByte
        self.flags = .init(firstByte: firstByte)
        self.address = .init(firstByte: index + 2)
        self.moveData = .init(firstByte: index + 2 + Data2ByteCell.size)
        self.data = .init(firstByte: index + 2 + Data2ByteCell.size + Data2ByteCell.size)
        self.commandFlag = self.data.index + 2
    }

    static let size = 3 + Data2ByteCell.size + Data2ByteCell.size + Data2ByteCell.size

    let commandFlag: Int

    let flags: Data2ByteCell
    let address: Data2ByteCell
    let moveData: Data2ByteCell
    let data: Data2ByteCell
}
