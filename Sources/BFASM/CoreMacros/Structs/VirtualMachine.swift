final class VirtualMachine {
    // only for test
    let register0: BigRegister16 = .init(firstByte: BigRegister16.size * 0)
    let register1: BigRegister16 = .init(firstByte: BigRegister16.size * 1)
    let register2: BigRegister16 = .init(firstByte: BigRegister16.size * 2)

    // real registers
    private(set) lazy var fastStack: Register16Stack = .init(firstByte: register2.index + BigRegister16.size)
    private(set) lazy var table2_n: Table2_n = .init(firstByte: fastStack.index + Register16Stack.size)

    private(set) lazy var input: InputRegister = .init(firstByte: table2_n.index + Table2_n.size)
    private(set) lazy var flags: RegisterFlags = .init(firstByte: input.index + InputRegister.size)
    
    private(set) lazy var tmp0: BigRegister16 = .init(firstByte: flags.index + RegisterFlags.size)
    private(set) lazy var tmp1: BigRegister16 = .init(firstByte: tmp0.index + BigRegister16.size)
    private(set) lazy var tmp2: BigRegister16 = .init(firstByte: tmp1.index + BigRegister16.size)
    private(set) lazy var tmp3: BigRegister16 = .init(firstByte: tmp2.index + BigRegister16.size)

    private(set) lazy var destination: BigRegister16 = .init(firstByte: tmp3.index + BigRegister16.size)
    private(set) lazy var operand: BigRegister16 = .init(firstByte: destination.index + BigRegister16.size)
    private(set) lazy var stack: BigRegister16 = .init(firstByte: operand.index + BigRegister16.size)

    private(set) lazy var tmp: Int = stack.index + BigRegister16.size
    private(set) lazy var microCode: MicroCode = .init(firstByte: tmp + 1)

    private(set) lazy var command: BigRegister16 = .init(firstByte: microCode.index + MicroCode.size)
    private(set) lazy var indexCommand: BigRegister16 = .init(firstByte: command.index + BigRegister16.size)

    private(set) lazy var r0: Data2ByteCell = .init(firstByte: indexCommand.index + BigRegister16.size)
    private(set) lazy var r1: Data2ByteCell = .init(firstByte: r0.index + Data2ByteCell.size)
    private(set) lazy var r2: Data2ByteCell = .init(firstByte: r1.index + Data2ByteCell.size)
    private(set) lazy var r3: Data2ByteCell = .init(firstByte: r2.index + Data2ByteCell.size)
    private(set) lazy var r4: Data2ByteCell = .init(firstByte: r3.index + Data2ByteCell.size)
    private(set) lazy var r5: Data2ByteCell = .init(firstByte: r4.index + Data2ByteCell.size)
    
    private(set) lazy var memory: Memory = .init(firstByte: r5.index + Data2ByteCell.size)
    
    func initMemory() -> IMacros {
        body {
            register0.initMemory()
            register1.initMemory()
            register2.initMemory()
            
            stack.initMemory()
            
            tmp0.initMemory()
            tmp1.initMemory()
            tmp2.initMemory()
            tmp3.initMemory()

            input.initMemory()
            
            command.initMemory()
            operand.initMemory()
        
            destination.initMemory()
            indexCommand.initMemory()
            
            microCode.initMemory()
            
            table2_n.initMemory()
        }
    }
}

protocol ICommandArgument {
    var ptrFlag: Int { get }
    var needLoad: Int { get }
    var register: Int { get }
}

struct MicroCodeCommandStack {
    static let size: Int = 4 + 4

    let index: Int
    let currentCode: Left4ByteFastZeroIfCell
    let element0: Int
    let element1: Int
    let element2: Int
    let element3: Int

    init(firstByte: Int) {
        self.currentCode = .init(firstByte: firstByte)
        self.element0 = firstByte + 4
        self.element1 = firstByte + 5
        self.element2 = firstByte + 6
        self.element3 = firstByte + 7
        self.index = firstByte
    }
    
    func initMemory() -> IMacros {
        currentCode.initMemory()
    }
    
    func pop() -> IMacros {
        body {
            MoveValue(dest: currentCode.value, src: element0)
            MoveValue(dest: element0, src: element1)
            MoveValue(dest: element1, src: element2)
            MoveValue(dest: element2, src: element3)
        }
    }
    
    func push(_ current: MicroCoreCommand) -> IMacros {
        body {
            MoveValue(dest: element3, src: element2)
            MoveValue(dest: element2, src: element1)
            MoveValue(dest: element1, src: element0)
            Set(index: element0, current.rawValue)
        }
    }
    
    // ==
    // push(c1)
    // push(c0)
    func push(_ c0: MicroCoreCommand, _ c1: MicroCoreCommand) -> IMacros {
        body {
            MoveValue(dest: element3, src: element1)
            MoveValue(dest: element2, src: element0)
            Set(index: element1, c1.rawValue)
            Set(index: element0, c0.rawValue)
        }
    }
    
    func push(_ c0: MicroCoreCommand, _ c1: MicroCoreCommand, _ c2: MicroCoreCommand) -> IMacros {
        body {
            MoveValue(dest: element3, src: element0)
            Set(index: element2, c2.rawValue)
            Set(index: element1, c1.rawValue)
            Set(index: element0, c0.rawValue)
        }
    }
    
    func convertToCommand(_ value: UInt8) -> MicroCoreCommand {
        MicroCoreCommand(rawValue: Int(value))!
    }

    func info(memory: inout [UInt8]) -> String {
        [
            convertToCommand(memory[element0]),
            convertToCommand(memory[element1]),
            convertToCommand(memory[element2]),
            convertToCommand(memory[element3]),
        ].map({ "\($0)" }).joined(separator: ", ")
    }
}

struct Register16Stack {
    static let size: Int = 16
    let index: Int
    
    let elements: [Data2ByteCell]
    
    init(firstByte: Int) {
        self.index = firstByte
        elements = (0..<8).map({ .init(firstByte: $0 * 2 + firstByte) })
    }
    
    func pushInBack(_ reg: BigRegister16) -> IMacros {
        body {
            elements[1].move(to: elements[0])
            elements[2].unsafeMove(to: elements[1])
            elements[3].unsafeMove(to: elements[2])
            elements[4].unsafeMove(to: elements[3])
            elements[5].unsafeMove(to: elements[4])
            elements[6].unsafeMove(to: elements[5])
            elements[7].unsafeMove(to: elements[6])
            reg.copy(to: elements[7])
        }
    }
    
    func pushInFront(_ reg: BigRegister16) -> IMacros {
        body {
            elements[6].move(to: elements[7])
            elements[5].unsafeMove(to: elements[6])
            elements[4].unsafeMove(to: elements[5])
            elements[3].unsafeMove(to: elements[4])
            elements[2].unsafeMove(to: elements[3])
            elements[1].unsafeMove(to: elements[2])
            elements[0].unsafeMove(to: elements[1])
            reg.copy(to: elements[0])
        }
    }
    
    func popFromBack(_ reg: BigRegister16) -> IMacros {
        body {
            elements[7].move(to: reg)
            elements[6].unsafeMove(to: elements[7])
            elements[5].unsafeMove(to: elements[6])
            elements[4].unsafeMove(to: elements[5])
            elements[3].unsafeMove(to: elements[4])
            elements[2].unsafeMove(to: elements[3])
            elements[1].unsafeMove(to: elements[2])
            elements[0].unsafeMove(to: elements[1])
        }
    }
    
    func popFromFront(_ cell: Data2ByteCell) -> IMacros {
        body {
            elements[0].move(to: cell)
            
            elements[1].unsafeMove(to: elements[0])
            elements[2].unsafeMove(to: elements[1])
            elements[3].unsafeMove(to: elements[2])
            elements[4].unsafeMove(to: elements[3])
            elements[5].unsafeMove(to: elements[4])
            elements[6].unsafeMove(to: elements[5])
            elements[7].unsafeMove(to: elements[6])
        }
    }

    func popFromFront(_ reg: BigRegister16) -> IMacros {
        body {
            elements[0].move(to: reg)

            elements[1].unsafeMove(to: elements[0])
            elements[2].unsafeMove(to: elements[1])
            elements[3].unsafeMove(to: elements[2])
            elements[4].unsafeMove(to: elements[3])
            elements[5].unsafeMove(to: elements[4])
            elements[6].unsafeMove(to: elements[5])
            elements[7].unsafeMove(to: elements[6])
        }
    }
}

struct MicroCode {
    static let size: Int = MicroCodeCommandStack.size + 1 + 5 + Data2ByteCell.size + Data2ByteCell.size + OperandInfo.size + DestinationInfo.size
    let commandStack: MicroCodeCommandStack
    
    let index: Int
    let isPtr: Int

    let memoryAddress: Data2ByteCell
    let memoryValue: Data2ByteCell
    let memoryCommand: Int
    let memorySkip: Int

    let value: Left3ByteFastZeroIfCell
    
    let operandInfo: OperandInfo
    let destinationInfo: DestinationInfo
    
    func initMemory() -> IMacros {
        body {
            value.init3Memory()
            commandStack.initMemory()
        }
    }

    struct OperandInfo: ICommandArgument {
        static let size: Int = 3
        
        let index: Int
    
        let ptrFlag: Int
        let needLoad: Int
        let register: Int
        
        init(firstByte: Int) {
            index = firstByte
            ptrFlag = firstByte
            needLoad = firstByte + 1
            register = firstByte + 2
        }
    }
    
    struct DestinationInfo: ICommandArgument {
        static let size: Int = 4

        let ptrFlag: Int
        let needLoad: Int
        let needSave: Int
        let register: Int
        
        init(firstByte: Int) {
            ptrFlag = firstByte
            needLoad = firstByte + 1
            needSave = firstByte + 2
            register = firstByte + 3
        }
    }
    
    init(firstByte: Int) {
        self.index = firstByte
        self.commandStack = MicroCodeCommandStack(firstByte: firstByte)
        self.isPtr = self.commandStack.index + MicroCodeCommandStack.size
        self.memoryAddress = .init(firstByte: self.isPtr + 1)
        self.memoryValue = .init(firstByte: self.memoryAddress.index + Data2ByteCell.size)
        self.memoryCommand = self.memoryValue.index + Data2ByteCell.size
        self.memorySkip = self.memoryCommand + 1
        self.value = .init(firstByte: self.memorySkip + 1)
        self.operandInfo = .init(firstByte: self.value.index + 3)
        self.destinationInfo = .init(firstByte: self.operandInfo.index + OperandInfo.size)
    }
    
}
