import Foundation

let base = URL(filePath: #file).deletingLastPathComponent()
let source = base.appending(path: "code")
let result = base.appending(path: "example")

func listFiles(in directory: URL, withExtension fileExtension: String) -> [URL] {
    let fileManager = FileManager.default
    var results: [URL] = []
    if let enumerator = fileManager.enumerator(at: directory, includingPropertiesForKeys: nil) {
        for case let fileURL as URL in enumerator {
            if fileURL.path().hasSuffix(fileExtension) {
                results.append(fileURL)
            }
        }
    }
    return results
}

func buildFile(_ url: URL) {
    let code = Builder(url.path).link()
    let name = url.deletingPathExtension().deletingPathExtension().lastPathComponent
    try! code.write(to: result.appending(path: "\(name).bfasm"), atomically: true, encoding: .utf8)
}


let allFiles = listFiles(in: source, withExtension: "main.exbfasm")
for file in allFiles {
    buildFile(file)
}
