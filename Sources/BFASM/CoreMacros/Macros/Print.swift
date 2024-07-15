func Print(_ tmp: Int, text: String) -> IMacros {
    SequenceMacros(
        macros: text.map({ $0.asciiValue! }).map { val in
            body {
                Set(index: tmp, Int(val))
                "."
                Set(index: tmp, 0)
            }
        }
    )
}
