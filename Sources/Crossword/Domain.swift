import CryptoKit
import Foundation

struct Domain {
    private var values = [Word]()
}

/// Initializers
extension Domain {
    init(for span: Span, using wordList: [Word]) {
        for word in wordList {
            guard word.count == span.length else {
                continue
            }
            values.append(word)
        }
    }
}

/// Collections
extension Domain: Collection {
    typealias Index = [Word].Index

    var startIndex: Index {
        values.startIndex
    }

    var endIndex: Index {
        values.endIndex
    }

    func index(after index: Index) -> Index {
        values.index(after: index)
    }

    subscript(_ index: Index) -> Word {
        values[index]
    }
}

/// Representations
extension Domain {
    var stringArrayRepresentation: [String] {
        values.map { String.init($0) }
    }
    var wordArrayRepresentation: [Word] {
        values
    }
}

/// Mutating
extension Domain {
    mutating func update(to newValues: [Word]) {
        values = newValues
    }

    mutating func update(remove word: Word) {
        guard let index = values.firstIndex(of: word) else {
            return
        }
        values.remove(at: index)
    }
}

extension Domain {
    func hash<F: HashFunction>(into hasher: inout F) {
        for word in values {
            let data = Data(word.stringRepresentation.utf8)
            hasher.update(data: data)
        }
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
