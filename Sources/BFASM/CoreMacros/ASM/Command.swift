import Foundation

class Command {
    let actions: [CommandVersionContainer]
    var baseOpCode: Int = 0
    let specialAction: ((VirtualMachine) -> IMacros)?
    let name: String
    
    init(name: String, specialAction: @escaping (VirtualMachine) -> IMacros) {
        self.name = name
        actions = []
        self.specialAction = specialAction
    }
    
    init(name: String, actions: [CommandArgumentCombinationAction]) {
        var values: [CommandVersionContainer] = []
        self.name = name
        self.specialAction = nil
        actions.forEach({ container in
            switch container {
            case .twoArgument(let a1, let a2, let action):
                let combination = CommandArgumentCombination(argument1: a1, argument2: a2)
                guard let pattern = allCommandArgumentPatterns.first(where: { combination == $0.combination }) else {
                    fatalError()
                }
                values.append(contentsOf: pattern.generateAllVersion(action))
            case .oneArgument(let a1, let action):
                let combination = CommandArgumentCombination(argument1: a1, argument2: nil)
                guard let pattern = allCommandArgumentPatterns.first(where: { combination == $0.combination }) else {
                    fatalError()
                }
                values.append(contentsOf: pattern.generateAllVersion({ vm, a1, _ in action(vm, a1) }))
            case .noArgument(let action):
                let combination = CommandArgumentCombination(argument1: nil, argument2: nil)
                guard let pattern = allCommandArgumentPatterns.first(where: { combination == $0.combination }) else {
                    fatalError()
                }
                values.append(contentsOf: pattern.generateAllVersion({ vm, _, _ in action(vm) }))
            }
        })
        assert(Set(values.map({ $0.localIndex })).count == values.count)
        self.actions = values
    }
}
