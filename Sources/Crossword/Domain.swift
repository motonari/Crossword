struct Domain {
    private var values = [[Character]]()
}

/// Initializers
extension Domain {
    init(for span: Span, using wordList: [String]) {
        for word in wordList {
            guard word.utf16.count == span.length else {
                continue
            }
            let value = [Character](word)
            values.append(value)
        }
    }
}

/// Collections
extension Domain: Collection {
    typealias Index = [[Character]].Index

    var startIndex: Index {
        values.startIndex
    }

    var endIndex: Index {
        values.endIndex
    }

    func index(after index: Index) -> Index {
        values.index(after: index)
    }

    subscript(_ index: Index) -> [Character] {
        values[index]
    }
}

/// Representations
extension Domain {
    var stringArrayRepresentation: [String] {
        values.map { String.init($0) }
    }
}

/// Mutating
extension Domain {
    mutating func update(to newValues: [String]) {
        values.removeAll()
        for word in newValues {
            var value = [Character]()
            for char in word {
                value.append(char)
            }
            values.append(value)
        }
    }

    mutating func update(remove word: String) {
        let value = word.map { $0 }
        guard let index = values.firstIndex(of: value) else {
            return
        }
        values.remove(at: index)
    }
}

/// Descriptions
extension Domain: CustomStringConvertible {
    var description: String {
        var wordList = [String]()
        for value in values {
            let word = String(value)
            wordList.append(word)
        }
        return "Domain(\(wordList))"
    }
}
