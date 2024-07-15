@resultBuilder
struct MacrosBuilder {
    static func buildOptional(_ component: IMacros?) -> any IMacros {
        if let component {
            return component
        }
        return emptyBody
    }

    static func buildBlock(_ components: IMacros...) -> IMacros {
        SequenceMacros(macros: components)
    }

    static func buildEither(first component: IMacros) -> IMacros {
        component
    }

    static func buildEither(second component: IMacros) -> IMacros {
        component
    }

    static func buildLimitedAvailability(_ component: IMacros) -> IMacros {
        component
    }
}

func body(@MacrosBuilder _ content: () -> IMacros) -> IMacros {
    content()
}

let emptyBody = body { }
