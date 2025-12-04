/// A word
public struct Word: Sendable {
    private let characters: [Character]
}

/// Initializers
extension Word {
    public init(_ s: String) {
        self.characters = [Character](s)
    }
}

/// Equatable
extension Word: Equatable {
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
