import XCTest
@testable import BFASM

final class Tests01Base: XCTestCase {
    func test00Register16Init() throws {
        var memory: [UInt8] = .init(repeating: 0, count: 256)
        let register = BigRegister16(firstByte: 0)
        let code = body {
            register.initMemory()
        }
        _ = brainfuckInterpreter(code: code, input: "", memory: &memory)
        XCTAssert(memory.checkRegister16Value(register, value: 0))
    }
    
    func test01Register16Inc() throws {
        var memory: [UInt8] = .init(repeating: 0, count: 256)
        let register = BigRegister16(firstByte: 0)
        let code = body {
            register.initMemory()
            register.inc16()
        }
        brainfuckInterpreter(code: code, memory: &memory)
        XCTAssert(memory.checkRegister16Value(register, value: 1))
        
        brainfuckInterpreter(code: register.inc16(), memory: &memory)
        XCTAssert(memory.checkRegister16Value(register, value: 2))
        
        memory.setRegister16Value(register, value: 0x00FF)
        brainfuckInterpreter(code: register.inc16(), memory: &memory)
        XCTAssert(memory.checkRegister16Value(register, value: 0x0100))
        
        memory.setRegister16Value(register, value: 0x01FF)
        brainfuckInterpreter(code: register.inc16(), memory: &memory)
        XCTAssert(memory.checkRegister16Value(register, value: 0x0200))

        brainfuckInterpreter(code: register.inc16(), memory: &memory)
        XCTAssert(memory.checkRegister16Value(register, value: 0x0201))
        
        memory.setRegister16Value(register, value: 0xFFFF)
        brainfuckInterpreter(code: register.inc16(), memory: &memory)
        XCTAssert(memory.checkRegister16Value(register, value: 0x0000))
    }
    
    func test02Register16Dec() throws {
        var memory: [UInt8] = .init(repeating: 0, count: 256)
        let register = BigRegister16(firstByte: 0)
        let code = body {
            register.initMemory()
            register.dec16()
        }
        brainfuckInterpreter(code: code, memory: &memory)
        XCTAssert(memory.checkRegister16Value(register, value: 0xFFFF))
        
        brainfuckInterpreter(code: register.dec16(), memory: &memory)
        XCTAssert(memory.checkRegister16Value(register, value: 0xFFFE))
        
        memory.setRegister16Value(register, value: 0x0100)
        brainfuckInterpreter(code: register.dec16(), memory: &memory)
        XCTAssert(memory.checkRegister16Value(register, value: 0x0FF))
        
        memory.setRegister16Value(register, value: 0x0200)
        brainfuckInterpreter(code: register.dec16(), memory: &memory)
        XCTAssert(memory.checkRegister16Value(register, value: 0x01FF))

        brainfuckInterpreter(code: register.dec16(), memory: &memory)
        XCTAssert(memory.checkRegister16Value(register, value: 0x01FE))
        
        memory.setRegister16Value(register, value: 0x0001)
        brainfuckInterpreter(code: register.dec16(), memory: &memory)
        XCTAssert(memory.checkRegister16Value(register, value: 0x0000))
    }
    
    func test03Register16SafeDec() throws {
        var memory: [UInt8] = .init(repeating: 0, count: 256)
        let register = BigRegister16(firstByte: 0)
        let code = body {
            register.initMemory()
            register.safeDec16()
        }
        brainfuckInterpreter(code: code, memory: &memory)
        XCTAssert(memory.checkRegister16Value(register, value: 0x0000))
        
        brainfuckInterpreter(code: register.safeDec16(), memory: &memory)
        XCTAssert(memory.checkRegister16Value(register, value: 0x0000))
        
        memory.setRegister16Value(register, value: 0x0100)
        brainfuckInterpreter(code: register.safeDec16(), memory: &memory)
        XCTAssert(memory.checkRegister16Value(register, value: 0x0FF))
        
        memory.setRegister16Value(register, value: 0x0200)
        brainfuckInterpreter(code: register.safeDec16(), memory: &memory)
        XCTAssert(memory.checkRegister16Value(register, value: 0x01FF))

        brainfuckInterpreter(code: register.safeDec16(), memory: &memory)
        XCTAssert(memory.checkRegister16Value(register, value: 0x01FE))
        
        memory.setRegister16Value(register, value: 0x0001)
        brainfuckInterpreter(code: register.safeDec16(), memory: &memory)
        XCTAssert(memory.checkRegister16Value(register, value: 0x0000))
    }
    
    func test04InitVM() throws {
        var memory: [UInt8] = .init(repeating: 0, count: 256)
        let vm = VirtualMachine()
        let code = body {
            vm.initMemory()
        }
        brainfuckInterpreter(code: code, memory: &memory)
        
        XCTAssert(memory.checkRegister16Value(vm.register0, value: 0x0000))
        XCTAssert(memory.checkRegister16Value(vm.register1, value: 0x0000))
        XCTAssert(memory.checkRegister16Value(vm.register2, value: 0x0000))
        XCTAssert(memory.checkRegister16Value(vm.tmp0, value: 0x0000))
        XCTAssert(memory.checkRegister16Value(vm.tmp1, value: 0x0000))
        XCTAssert(memory.checkRegister16Value(vm.tmp2, value: 0x0000))
    }
    
    func test05Copy() {
        var memory: [UInt8] = .init(repeating: 0, count: 256)
        memory[0] = 0x0001
        
        brainfuckInterpreter(&memory) {
            CopyValue(dest: 1, src: 0, tmp: 2)
        }
        
        XCTAssert(memory[0] == 0x0001)
        XCTAssert(memory[1] == 0x0001)
    }
    
    func test06RegisterCopy() {
        var memory: [UInt8] = .init(repeating: 0, count: 256)
        let vm = VirtualMachine()
        let code = body {
            vm.initMemory()
        }
        brainfuckInterpreter(code: code, memory: &memory)
        
        memory.setRegister16Value(vm.register0, value: 0x0001)
        brainfuckInterpreter(&memory) {
            vm.register0.copy(to: vm.register1)
        }
        XCTAssert(memory.checkRegister16Value(vm.register0, value: 0x0001))
        XCTAssert(memory.checkRegister16Value(vm.register1, value: 0x0001))
    }
    
    func test06RegisterToDataCopy() {
        var memory: [UInt8] = .init(repeating: 0, count: 256)
        let vm = VirtualMachine()
        let code = body {
            vm.initMemory()
        }
        brainfuckInterpreter(code: code, memory: &memory)
        
        memory.setRegister16Value(vm.register0, value: 0x1020)
        brainfuckInterpreter(&memory) {
            vm.register0.copy(to: vm.memory.firstCell.data)
        }
        XCTAssert(memory.checkRegister16Value(vm.register0, value: 0x1020))
        XCTAssert(memory.getValue(vm.memory.firstCell.data) == 0x1020)
    }
    
    func test06DataToRegisterCopy() {
        var memory: [UInt8] = .init(repeating: 0, count: 256)
        let vm = VirtualMachine()
        let code = body {
            vm.initMemory()
        }
        brainfuckInterpreter(code: code, memory: &memory)
        
        memory.setValue(vm.memory.firstCell.data, value: 0x1020)

        brainfuckInterpreter(&memory) {
            vm.memory.firstCell.data.copy(to: vm.register0)
        }
        XCTAssert(memory.checkRegister16Value(vm.register0, value: 0x1020))
        XCTAssert(memory.getValue(vm.memory.firstCell.data) == 0x1020)
    }
    
    func test06RegisterLowCheckZero() {
        var memory: [UInt8] = .init(repeating: 0, count: 256)
        let vm = VirtualMachine()
        
        var izZero = false
        var isNotZero = false
        
        brainfuckInterpreter(&memory) {
            vm.register0.lowCell.if(requiredInit: true) {
                CustomBreakPoint { _, _ in
                    isNotZero = true
                }
            } zero: {
                CustomBreakPoint { _, _ in
                    izZero = true
                }
            }
        }
        XCTAssert(izZero && !isNotZero)
        XCTAssert(memory.checkRegister16Value(vm.register0, value: 0x0000))
    }
    
    func test07RegisterLowCheckZero() {
        var memory: [UInt8] = .init(repeating: 0, count: 256)
        let vm = VirtualMachine()
        
        var izZero = false
        var isNotZero = false
        
        memory.setRegister16Value(vm.register0, value: 0x0001)
        
        brainfuckInterpreter(&memory) {
            vm.register0.lowCell.if(requiredInit: true) {
                CustomBreakPoint { _, _ in
                    isNotZero = true
                }
            } zero: {
                CustomBreakPoint { _, _ in
                    izZero = true
                }
            }
        }
        XCTAssert(!izZero && isNotZero)
        XCTAssert(memory.checkRegister16Value(vm.register0, value: 0x0001))
    }
    
    func test07RegisterHighCheckZero() {
        var memory: [UInt8] = .init(repeating: 0, count: 256)
        let vm = VirtualMachine()
        
        var izZero = false
        var isNotZero = false
        
        brainfuckInterpreter(&memory) {
            vm.register0.highCell.if(requiredInit: true) {
                CustomBreakPoint { _, _ in
                    isNotZero = true
                }
            } zero: {
                CustomBreakPoint { _, _ in
                    izZero = true
                }
            }
        }
        XCTAssert(izZero && !isNotZero)
        XCTAssert(memory.checkRegister16Value(vm.register0, value: 0x0))
    }
    
    func test08RegisterHighCheckZero() {
        var memory: [UInt8] = .init(repeating: 0, count: 256)
        let vm = VirtualMachine()
        
        var izZero = false
        var isNotZero = false
        
        memory.setRegister16Value(vm.register0, value: 0x0100)
        
        brainfuckInterpreter(&memory) {
            vm.register0.highCell.if(requiredInit: true) {
                CustomBreakPoint { _, _ in
                    isNotZero = true
                }
            } zero: {
                CustomBreakPoint { _, _ in
                    izZero = true
                }
            }
        }
        XCTAssert(!izZero && isNotZero)
        XCTAssert(memory.checkRegister16Value(vm.register0, value: 0x0100))
    }
}

