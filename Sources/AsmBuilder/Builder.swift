import Foundation

class Builder {
    private var currentBlock: Block = .init(name: "root", parent: nil)
    private var openFiles: [URL] = []
    private var index: Int = 0

    init(_ path: String) {
        openFile(path)
    }
    
    func link() -> String {
        assert(currentBlock.parent == nil)
        return currentBlock.link()
    }
    
    private func openFile(_ path: String) {
        let fullPath: URL
        if let last = openFiles.last {
            fullPath = last.deletingLastPathComponent().appending(path: path)
        } else {
            fullPath = URL(filePath: path)
        }
        openFiles.append(fullPath)
        let code = try! String(contentsOf: fullPath)
        add(code: code)
        openFiles.removeLast()
    }
    
    private func add(code: String) {
        code.components(separatedBy: ";").forEach({ prepareCommand(input: $0) })
    }
    
    private func checkArgument(_ arg: String) -> Bool {
        return Int(arg) != nil || arg.hasPrefix("%")
    }
    
    private func argument(_ arg: String) -> String {
        if arg == "'\\t'" {
            return "\("\t".first!.asciiValue!)"
        }
        if arg == "'\\n'" {
            return "\("\n".first!.asciiValue!)"
        }
        if arg == "'\\s'" {
            return "\(" ".first!.asciiValue!)"
        }
        if arg == "'\\z'" {
            return "\(",".first!.asciiValue!)"
        }
        if arg == "'\\e'" {
            return "\(";".first!.asciiValue!)"
        }
        if arg.first == "'" {
            assert(arg.last == "'" && arg.count == 3)
            return "\(arg.dropFirst().dropLast().first!.asciiValue!)"
        }
        return arg
    }
    
    private func prepareCommand(input: String) {
        let shift = input.filter({ $0 == "\t" })
        
        let elements = input
            .replacingOccurrences(of: ",", with: "")
            .replacingOccurrences(of: "\n", with: "")
            .replacingOccurrences(of: "\t", with: "")
            .components(separatedBy: " ").filter({ !$0.isEmpty })
        if elements.isEmpty {
            return
        }
        if elements[0] == "import" {
            assert(elements.count == 2)
            openFile(elements[1])
            return
        }
        if elements[0] == "#def" {
            assert(elements.count == 3)
            currentBlock.labels["\(elements[1])"] = Int(elements[2])!
            currentBlock.appendRow(shift + input + ";")
            return
        }
        if elements[0] == "if" {
            assert(elements.count == 4)
            let a = elements[1]
            let con = elements[2]
            let b = elements[3]
            
            let name = ":\(index)"
            currentBlock = .init(name: name, parent: currentBlock)
            currentBlock.labels["start"] = index
            currentBlock.appendRow(shift + "#start block \(name);")
            
            var size = (checkArgument(argument(a)) || checkArgument(argument(b))) ? 2 : 1
            index += size
            currentBlock.appendRow(shift + "cmp \(argument(a)), \(argument(b)); # \(index - size) \(size);")
            
            size = 2
            if con == "==" {
                index += 2
                currentBlock.appendRow("j!= %skipTrue%; # \(index - size) \(size);")
                return
            }
            if con == "!=" {
                index += 2
                currentBlock.appendRow("j== %skipTrue%; # \(index - size) \(size);")
                return
            }
            if con == ">" {
                index += 2
                currentBlock.appendRow("j=< %skipTrue%; # \(index - size) \(size);")
                return
            }
            if con == ">=" {
                index += 2
                currentBlock.appendRow("j< %skipTrue%; # \(index - size) \(size);")
                return
            }
            if con == "<=" {
                index += 2
                currentBlock.appendRow("j> %skipTrue%; # \(index - size) \(size);")
                return
            }
            if con == "<" {
                index += 2
                currentBlock.appendRow("j=> %skipTrue%; # \(index - size) \(size);")
                return
            }
            assert(false)
            return
        }
        if elements[0] == "startBlock" {
            assert(elements.count < 3)
            var name = ":\(index)"
            if elements.count == 2 {
                name = elements[1]
                currentBlock.labels["\(name)"] = index
            }
            currentBlock = .init(name: name, parent: currentBlock)
            currentBlock.labels["start"] = index
            currentBlock.appendRow(shift + "#start block \(name);")
            return
        }
        if elements[0] == "endBlock" || elements[0] == "else" {
            let elseName = "elseEndIndex:\(index)"
            currentBlock.labels["end"] = index
            if elements[0] == "else" {
                index += 2;
                currentBlock.appendRow("jmp %\(elseName)%; #skip else block \(index - 2) \(2);")
            }
            currentBlock.labels["skipTrue"] = index
            let text = currentBlock.link()
            let endLabel = currentBlock.endLabel
            currentBlock = currentBlock.parent!
            if let endLabel {
                currentBlock.labels[endLabel] = index
            }
            currentBlock.appendRow(text)
            if elements[0] == "else" {
                let name = "else:\(index)"
                currentBlock = .init(name: name, parent: currentBlock, endLabel: elseName)
                currentBlock.labels["start"] = index
                currentBlock.appendRow(shift + "#else block \(name);")
            }
            return
        }
        if elements[0] == "label" {
            assert(elements.count == 2)
            currentBlock.labels[elements[1]] = index
            currentBlock.appendRow(shift + "#\(elements[1])=\(index);")
            return
        }
        if elements[0].first == "#" {
            currentBlock.appendRow(shift + input + ";")
            return
        }
        if elements.count == 1 {
            index += 1
            currentBlock.appendRow(shift + "\(elements[0]); # \(index - 1) 1;")
            return
        }
        if elements.count == 2 {
            let size = checkArgument(argument(elements[1])) ? 2 : 1
            index += size
            currentBlock.appendRow(shift + "\(elements[0]) \(argument(elements[1])); # \(index - size) \(size);")
            return
        }
        if elements.count == 3 {
            let size = (checkArgument(argument(elements[1])) || checkArgument(argument(elements[2]))) ? 2 : 1
            index += size
            currentBlock.appendRow(shift + "\(elements[0]) \(argument(elements[1])), \(argument(elements[2])); # \(index - size) \(size);")
            return
        }
        fatalError()
    }
}

extension Builder {
    private final class Block {
        let name: String
        let parent: Block?
        var text: String = ""
        var endLabel: String? = nil
        var labels: [String: Int] = [:]
        
        init(name: String, parent: Block?, endLabel: String? = nil) {
            self.name = name
            self.parent = parent
            self.endLabel = endLabel
        }
        
        func link() -> String {
            labels.forEach { con in
                text = text.replacingOccurrences(of: "%\(con.key)%", with: "\(con.value)")
            }
            return text
        }
        
        func appendRow(_ text: String) {
            self.text = self.text + "\n" + text
        }
    }
}
