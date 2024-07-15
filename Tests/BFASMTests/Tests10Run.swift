import XCTest
@testable import BFASM
    
class Tests10Run: XCTestCase {
    func test01RunProgram() {
        var memory: [UInt8] = .init(repeating: 0, count: 256 * 256 * 50)
        let vm = VirtualMachine()
        let code = """
        mov r0 100;
        mov r1 r0;
        mov ptr r2 12;
        exit 0;
        run
        """
        let pool = CommandPool(vm: vm)
        brainfuckInterpreter(input: code, &memory) {
            vm.initMemory()
            pool.parser.loadProgram()
            pool.executor.runProgram()
        }
        XCTAssert(memory.checkRegister16Value(vm.register0, value: 100))
        XCTAssert(memory.checkRegister16Value(vm.register1, value: 100))
        XCTAssert(memory.checkRegister16Value(vm.register2, value: 0))
        XCTAssert(memory.getValue(vm.memory.firstCell.data) == 12)
    }
    
    func test02RunProgram() {
        var memory: [UInt8] = .init(repeating: 0, count: 256 * 256 * 50)
        let vm = VirtualMachine()
        let code = """
        mov r0 1;
        mov r1 2;
        mov r2 3;
        mov r3 4;
        mov r4 5;
        mov r5 6;
        
        mov ptr r0 1;
        mov ptr r1 2;
        mov ptr r2 3;
        mov ptr r3 4;
        mov ptr r4 5;
        mov ptr r5 6;
        
        exit 0;
        run
        """
        let pool = Command2Pool(vm: vm)
        let parser = Command2Parser(commands: pool.commands, vm: vm)
        let core = MicroCore(pool: pool, vm: vm)
        brainfuckInterpreter(input: code, &memory) {
            vm.initMemory()
            parser.loadProgram()
            core.loop()
        }
        XCTAssert(vm.r0.value(&memory) == 1)
        XCTAssert(vm.r1.value(&memory) == 2)
        XCTAssert(vm.r2.value(&memory) == 3)
        XCTAssert(vm.r3.value(&memory) == 4)
        XCTAssert(vm.r4.value(&memory) == 5)
        XCTAssert(vm.r5.value(&memory) == 6)
        
        XCTAssert(memory.dump(vm).prefix(7).dropFirst() == [1, 2, 3, 4, 5, 6])
    }
    
    func test03RunProgram() {
        var memory: [UInt8] = .init(repeating: 0, count: 256 * 256 * 50)
        let vm = VirtualMachine()
        let code = """
        mov r0 1;
        mov r1 2;
        mov r2 3;
        mov r3 4;
        mov r4 5;
        mov r5 6;
        
        mov ptr r0 r0;
        mov ptr r1 r1;
        mov ptr r2 r2;
        mov ptr r3 r3;
        mov ptr r4 r4;
        mov ptr r5 r5;
        
        exit 0;
        run
        """
        let pool = Command2Pool(vm: vm)
        let parser = Command2Parser(commands: pool.commands, vm: vm)
        let core = MicroCore(pool: pool, vm: vm)
        brainfuckInterpreter(input: code, &memory) {
            vm.initMemory()
            parser.loadProgram()
            core.loop()
        }
        XCTAssert(vm.r0.value(&memory) == 1)
        XCTAssert(vm.r1.value(&memory) == 2)
        XCTAssert(vm.r2.value(&memory) == 3)
        XCTAssert(vm.r3.value(&memory) == 4)
        XCTAssert(vm.r4.value(&memory) == 5)
        XCTAssert(vm.r5.value(&memory) == 6)
        
        XCTAssert(memory.dump(vm).prefix(7).dropFirst() == [1, 2, 3, 4, 5, 6])
    }
    
    func test04RunProgram() {
        var memory: [UInt8] = .init(repeating: 0, count: 256 * 256 * 50)
        let vm = VirtualMachine()
        let code = """
        add r0 1;
        add r1 2;
        add r1 r0;
        
        add ptr r0 r0;
        
        exit 0;
        run
        """
        let pool = Command2Pool(vm: vm)
        let parser = Command2Parser(commands: pool.commands, vm: vm)
        let core = MicroCore(pool: pool, vm: vm)
        brainfuckInterpreter(input: code, &memory) {
            vm.initMemory()
            parser.loadProgram()
            core.loop()
        }
        XCTAssert(vm.r0.value(&memory) == 1)
        XCTAssert(vm.r1.value(&memory) == 3)
        
        XCTAssert(memory.dump(vm)[1] == 2)
    }
    
    func test06RunProgram() {
        var memory: [UInt8] = .init(repeating: 0, count: 256 * 256 * 50)
        let vm = VirtualMachine()
        let code = """
        mov r1 2;
        mul r1 4;
                
        exit 0;
        run
        """
        let pool = Command2Pool(vm: vm)
        let parser = Command2Parser(commands: pool.commands, vm: vm)
        let core = MicroCore(pool: pool, vm: vm)
        brainfuckInterpreter(input: code, &memory) {
            vm.initMemory()
            parser.loadProgram()
            core.loop()
        }
        XCTAssert(vm.r1.value(&memory) == 8)
    }
    
    func test07RunProgram() {
        var memory: [UInt8] = .init(repeating: 0, count: 256 * 256 * 50)
        let vm = VirtualMachine()
        let code = """
        mov r1 8;
        div r1 2;
                
        exit 0;
        run
        """
        let pool = Command2Pool(vm: vm)
        let parser = Command2Parser(commands: pool.commands, vm: vm)
        let core = MicroCore(pool: pool, vm: vm)
        brainfuckInterpreter(input: code, &memory) {
            vm.initMemory()
            parser.loadProgram()
            core.loop()
        }
        XCTAssert(vm.r1.value(&memory) == 4)
    }
    
    func test08PushRunProgram() {
        var memory: [UInt8] = .init(repeating: 0, count: 256 * 256 * 50)
        let vm = VirtualMachine()
        let code = """
        mov r0 100;
        push r0;
        push 20;
        
        exit 0;
        run;
        """
        let pool = Command2Pool(vm: vm)
        let parser = Command2Parser(commands: pool.commands, vm: vm)
        let core = MicroCore(pool: pool, vm: vm)
        let out = brainfuckInterpreter(input: code, &memory) {
            vm.initMemory()
            parser.loadProgram()
            CustomBreakPoint { memory, currentPoint in
                XCTAssert(memory.checkRegister16Value(vm.stack, value: 7))
            }
            core.loop()
        }
        XCTAssert(memory.checkRegister16Value(vm.stack, value: 9))
        XCTAssert(memory.dump(vm)[9] == 20)
        XCTAssert(memory.dump(vm)[8] == 100)
        XCTAssert(vm.r0.value(&memory) == 100)
    }
    
    func test08PopRunProgram() {
        var memory: [UInt8] = .init(repeating: 0, count: 256 * 256 * 50)
        let vm = VirtualMachine()
        let code = """
        mov r0 100;
        
        push r0;
        get r5, 0;
        push 20;
        
        get r3, 0;
        get r4, 1;
        
        pop r1;
        pop r2;
        
        exit 0;

        run;
        """
        let pool = Command2Pool(vm: vm)
        let parser = Command2Parser(commands: pool.commands, vm: vm)
        let core = MicroCore(pool: pool, vm: vm)
        brainfuckInterpreter(input: code, &memory) {
            vm.initMemory()
            parser.loadProgram()
            CustomBreakPoint { memory, currentPoint in
                XCTAssert(memory.checkRegister16Value(vm.stack, value: 15))
            }
            core.loop()
        }
        XCTAssert(memory.checkRegister16Value(vm.stack, value: 15))
        
        XCTAssert(memory.dump(vm)[17] == 20)
        XCTAssert(memory.dump(vm)[16] == 100)
        
        XCTAssert(vm.r0.value(&memory) == 100)
        XCTAssert(vm.r1.value(&memory) == 20)
        XCTAssert(vm.r2.value(&memory) == 100)
        XCTAssert(vm.r5.value(&memory) == 100)
        XCTAssert(vm.r4.value(&memory) == 100)
        XCTAssert(vm.r3.value(&memory) == 20)
    }
    
    func test09IfJmpProgram() {
        jmpIfTest(cmp: true, value: 10, valueB: 10)
        jmpIfTest(cmp: true, value: 0, valueB: 0)
        jmpIfTest(cmp: true, value: 10, valueB: 12)
        jmpIfTest(cmp: true, value: 12, valueB: 10)
        jmpIfTest(cmp: true, value: 0, valueB: 1)
        jmpIfTest(cmp: true, value: 1, valueB: 0)
        jmpIfTest(cmp: true, value: 49, valueB: 48)

        jmpIfTest(cmp: false, value: 10, valueB: 10)
        jmpIfTest(cmp: false, value: 0, valueB: 0)
        jmpIfTest(cmp: false, value: 10, valueB: 12)
        jmpIfTest(cmp: false, value: 12, valueB: 10)
        jmpIfTest(cmp: false, value: 0, valueB: 1)
        jmpIfTest(cmp: false, value: 1, valueB: 0)
        jmpIfTest(cmp: false, value: 49, valueB: 48)

    }
    
    func jmpIfTest(cmp: Bool, value: UInt16, valueB: UInt16) {
        var memory: [UInt8] = .init(repeating: 0, count: 256 * 256 * 50)
        let vm = VirtualMachine()
        let code = """
        mov r0, \(value);
        \(cmp ? "cmp" : "sub") r0, \(valueB); # next 4;
        j== 8;
        add r1, 1;
        
        j!= 12;
        add r1, 2;

        j> 16;
        add r1, 4;
        
        j=> 20;
        add r1, 8;
        
        j=< 24;
        add r1, 16;
        
        j< 28;
        add r1, 32;
        
        exit 0;
        
        run;
        """
        let pool = Command2Pool(vm: vm)
        let parser = Command2Parser(commands: pool.commands, vm: vm)
        let core = MicroCore(pool: pool, vm: vm)
        let out = brainfuckInterpreter(input: code, &memory) {
            vm.initMemory()
            parser.loadProgram()
            core.loop()
        }

        var result = 0
        if !(value == valueB) { result += 1 }
        if !(value != valueB) { result += 2 }
        if !(value > valueB) { result += 4 }
        if !(value >= valueB) { result += 8 }
        if !(value <= valueB) { result += 16 }
        if !(value < valueB) { result += 32 }

        XCTAssert(vm.r1.value(&memory) == result)
        if cmp {
            XCTAssert(vm.r0.value(&memory) == value)
        } else {
            let result = (Int(value) - Int(valueB) + (0xFFFF + 1)) % (0xFFFF + 1)
            XCTAssert(vm.r0.value(&memory) == result)
        }
    }
    
    func test10Call() {
        var memory: [UInt8] = .init(repeating: 0, count: 256 * 256 * 50)
        let vm = VirtualMachine()
        let code = """
        jmp 4;
        
        exit 0; # 2 2;
        
        call 2;

        run;
        """
        let pool = Command2Pool(vm: vm)
        let parser = Command2Parser(commands: pool.commands, vm: vm)
        let core = MicroCore(pool: pool, vm: vm)
        brainfuckInterpreter(input: code, &memory) {
            vm.initMemory()
            parser.loadProgram()
            CustomBreakPoint { memory, currentPoint in
                XCTAssert(memory.checkRegister16Value(vm.stack, value: 6))
            }
            core.loop()
        }
        XCTAssert(memory.checkRegister16Value(vm.indexCommand, value: 4))
        XCTAssert(memory.checkRegister16Value(vm.stack, value: 7))
        XCTAssert(memory.dump(vm)[7] == 6)
    }
    
    func test10Ret() {
        var memory: [UInt8] = .init(repeating: 0, count: 256 * 256 * 50)
        let vm = VirtualMachine()
        let code = """
        jmp 5; # 0 2;
        
        mov r0, 2; # 2 2;
        ret; # 4 1;
        
        call 2; # 5 2;
        
        exit 0; # 7 2;

        run;
        """
        let pool = Command2Pool(vm: vm)
        let parser = Command2Parser(commands: pool.commands, vm: vm)
        let core = MicroCore(pool: pool, vm: vm)
        brainfuckInterpreter(input: code, &memory) {
            vm.initMemory()
            parser.loadProgram()
            CustomBreakPoint { memory, currentPoint in
                XCTAssert(memory.checkRegister16Value(vm.stack, value: 9))
            }
            core.loop()
        }
        XCTAssert(memory.checkRegister16Value(vm.indexCommand, value: 9))
        XCTAssert(memory.checkRegister16Value(vm.stack, value: 9))
        XCTAssert(memory.dump(vm)[10] == 7)
        XCTAssert(vm.r0.value(&memory) == 2)
    }
    
    func test11RunProgram() {
        var memory: [UInt8] = .init(repeating: 0, count: 256 * 256 * 50)
        let vm = VirtualMachine()
        let code = """
        jmp 39; # 0 2;

        # read int10;
        #readInt10=2;
        push r1; # 2 1;
        mov r0, 0; # 3 2;
        #loopInt10=5;
        input r1; # 5 1;
        sub r1, 48; # 6 2;
        j< 19; # 8 2;
        cmp r1, 9; # 10 2;
        j> 19; # 12 2;
        mul r0, 10; # 14 2;
        add r0, r1; # 16 1;
        jmp 5; # 17 2;
        #endInt10=19;
        resIn; # 19 1;
        pop r1; # 20 1;
        ret; # 21 1;

        # skip space;
        #skipSpace=22;
        push r0; # 22 1;
        #loopSpace=23;
        input r0; # 23 1;
        cmp r0, 32; # 24 2;
        j== 23; # 26 2;
        cmp r0, 10; # 28 2;
        j== 23; # 30 2;
        cmp r0, 9; # 32 2;
        j== 23; # 34 2;
        resIn; # 36 1;
        pop r0; # 37 1;
        ret; # 38 1;
        #main=39;
        call 22; # 39 2;
        call 2; # 41 2;
        exit 0; # 43 2;

        run
        
        12345
        
        """
        let pool = Command2Pool(vm: vm)
        let parser = Command2Parser(commands: pool.commands, vm: vm)
        let core = MicroCore(pool: pool, vm: vm)
        let out = brainfuckInterpreter(input: code, &memory) {
            vm.initMemory()
            parser.loadProgram()
            core.loop()
        }
        print(out)
        XCTAssert(vm.r0.value(&memory) == 12345)
    }
    
    func test12RunProgram() {
        var memory: [UInt8] = .init(repeating: 0, count: 256 * 256 * 50)
        let vm = VirtualMachine()
        let code = """
        jmp 26; # 0 2;


        # print int10;
        #printInt10=2;
        push r0; # 2 1;
        push r1; # 3 1;
        mov r1, 0; # 4 2;
        fPush 10; # 6 2;
        #loop1=8;
        div r0, 10; # 8 2;
        cmp r0; # 10 1;
        j> 8; # 11 2;
        #loop2=13;
        fPop r0; # 13 1;
        cmp r0, 10; # 14 2;
        j== 23; # 16 2;
        add r0, 48; # 18 2;
        out r0; # 20 1;
        jmp 13; # 21 2;
        #endLoop2=23;
        pop r1; # 23 1;
        pop r0; # 24 1;
        ret; # 25 1;
        #main=26;
        mov r0, 12345; # 26 2;
        call 2; # 28 2;

        exit 0;

        run
        """
        let pool = Command2Pool(vm: vm)
        let parser = Command2Parser(commands: pool.commands, vm: vm)
        let core = MicroCore(pool: pool, vm: vm)
        let out = brainfuckInterpreter(input: code, &memory) {
            vm.initMemory()
            parser.loadProgram()
            core.loop()
        }
        XCTAssert(out.hasSuffix("I/O:\n12345"))
        XCTAssert(vm.r0.value(&memory) == 12345)
    }
    
    
    func test13RunProgram() {
        var memory: [UInt8] = .init(repeating: 0, count: 256 * 256 * 50)
        let vm = VirtualMachine()
        let code = """
        jmp 63; # 0 2;

        #start block skipSpace;
        push r0; # 2 1;

        #start block :3;
        input r0; # 3 1;
        cmp r0, 32; # 4 2;
        j== 3; # 6 2;
        cmp r0, 10; # 8 2;
        j== 3; # 10 2;
        cmp r0, 9; # 12 2;
        j== 3; # 14 2;
        resIn; # 16 1;
        pop r0; # 17 1;
        ret; # 18 1;

        #start block printInt10;
        push r0; # 19 1;
        push r1; # 20 1;
        mov r1, 0; # 21 2;
        fPush 10; # 23 2;

        #start block :25;
        div r0, 10; # 25 2;
        cmp r0; # 27 1;
        j> 25; # 28 2;

        #start block :30;
        fPop r0; # 30 1;
        cmp r0, 10; # 31 2;
        j== 40; # 33 2;
        add r0, 48; # 35 2;
        out r0; # 37 1;
        jmp 30; # 38 2;
        pop r1; # 40 1;
        pop r0; # 41 1;
        ret; # 42 1;

        #start block readInt10;
        push r1; # 43 1;
        mov r0, 0; # 44 2;

        #start block :46;
        input r1; # 46 1;
        sub r1, 48; # 47 2;
        j< 60; # 49 2;
        cmp r1, 9; # 51 2;
        j> 60; # 53 2;
        mul r0, 10; # 55 2;
        add r0, r1; # 57 1;
        jmp 46; # 58 2;
        resIn; # 60 1;
        pop r1; # 61 1;
        ret; # 62 1;

        #start block main;
        call 2; # 63 2;
        call 43; # 65 2;
        mov r3, r0; # 67 1;
        mov r0, 1; # 68 2;
        mov r5, 0; # 70 2;

        #start block :72;
        sub r3, 1; # 72 2;
        j== 102; # 74 2;
        inc r0; # 76 1;
        mov r1, r5; # 77 1;

        #start block :78;
        sub r1, 1; # 78 2;
        j< 94; # 80 2;
        get r4, r1; # 82 1;
        mov r2, r0; # 83 1;
        mod r2, r4; # 84 1;
        sub r2; # 85 1;
        j== 100; # 86 2;
        sub s0, 2; # 88 2;
        j=< 94; # 90 2;
        jmp 78; # 92 2;
        #save=94;
        inc r5; # 94 1;
        push r0; # 95 1;
        call 19; # 96 2;
        out 32; # 98 2;
        #notSave=100;
        jmp 72; # 100 2;
        exit 0; # 102 2;

        run
        
        7
        """
        let pool = Command2Pool(vm: vm)
        let parser = Command2Parser(commands: pool.commands, vm: vm)
        let core = MicroCore(pool: pool, vm: vm)
        let out = brainfuckInterpreter(input: code, &memory) {
            vm.initMemory()
            parser.loadProgram()
            core.loop()
        }
        XCTAssert(out.hasSuffix("2 3 5 7 "))
    }
}
