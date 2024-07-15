struct Left3ByteFastZeroIfCell: ILeft3ByteFastZeroIfCell, IValueIndex {
    var value: Int
    
    let index: Int
    
    let zero0: Int
    let one0: Int
    
    init(firstByte: Int) {
        self.index = firstByte
        
        self.value = firstByte
        self.zero0 = firstByte + 1
        self.one0 = firstByte + 2
    }
    
    func info(_ memory: inout [UInt8]) -> String {
        "\(Int(memory[value]))"
    }
}

protocol ILeft3ByteFastZeroIfCell: I3ByteCell {
    var index: Int { get }
}

extension ILeft3ByteFastZeroIfCell {
    func ifNotZero(
        requiredInit: Bool = false,
        @MacrosBuilder _ notZero: () -> IMacros
    ) -> IMacros {
        let notZero = notZero()

        // v 0 1
        return body {
            ActiveCell(index) {
                UnsafeMacros {
                    if requiredInit {
                        init3Memory()
                    }
                    "["
                        notZero
                        SetCell(index)
                    ">]>[<]<"
                }
            }

        }
    }
}
