/// A word
public struct Word: Sendable, Equatable, Hashable {
    private let characters: [Character]
}

// MARK: Initializers
extension Word {
    public init(_ s: String) {
        self.characters = [Character](s)
    }
}

extension Word {
    var stableHashValue: Int {
        characters.reduce(1) { result, ch in
            result
                ^ ch.utf8.reduce(1) { result, code in
                    result + Int(code)
                }
        }
    }
}

/// Collection
extension Word: Collection {
    public typealias Index = [Character].Index

    public var startIndex: Index {
        characters.startIndex
    }

    public var endIndex: Index {
        characters.endIndex
    }

    public func index(after index: Index) -> Index {
        characters.index(after: index)
    }

    public subscript(_ index: Index) -> Character {
        characters[index]
    }
}

/// Representations
extension Word {
    var stringRepresentation: String {
        String(characters)
    }
}

/// Description
extension Word: CustomStringConvertible {
    public var description: String {
        String(characters)
    }
}
