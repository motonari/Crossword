struct Domain {
    var values: [String]

    init(for span: Span, using wordList: [String]) {
        values = wordList.filter { word in word.count == span.length }
    }

    var isEmpty: Bool {
        values.isEmpty
    }
}

extension Domain: CustomStringConvertible {
    var description: String {
        "Domain(\(values))"
    }
}
