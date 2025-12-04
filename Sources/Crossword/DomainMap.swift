/// Dictionary of CSP variables.
struct DomainMap {
    let crossword: Crossword
    var domains: [Span: Domain]

    mutating func reduceArc(
        of targetSpan: Span,
        using referenceSpan: Span
    ) -> Bool {

        guard
            let (targetCharIndex, referenceCharIndex) =
                crossword.crossIndices(of: SpanPair(targetSpan, referenceSpan))
        else {
            fatalError(
                "reduceArc must be called with overlapping spans. \(targetSpan) and \(referenceSpan) do not share a cell."
            )
        }
        let referenceDomain = domains[referenceSpan]!

        var validWords = [Word]()
        var changed = false
        for targetValue in domains[targetSpan]! {
            let overlapCharacter = targetValue[targetCharIndex]

            let match =
                referenceDomain.first { referenceValue in
                    referenceValue[referenceCharIndex] == overlapCharacter
                } != nil

            if match {
                validWords.append(targetValue)
            } else {
                changed = true
            }
        }

        if validWords.count == 1 {
            // Target span's domain is reduced to one. Now, make
            // sure the word has not been used yet.
            for (span, domain) in domains {
                if span == targetSpan {
                    continue
                }

                if domain.count == 1 && validWords[0] == domain[0] {
                    validWords = []
                    changed = true
                    break
                }
            }
        }

        if changed {
            update(span: targetSpan, values: validWords)
        }

        return changed
    }

    func domain(for span: Span) -> Domain {
        domains[span]!
    }

    var stringRepresentation: String {
        let charRow = [Character](repeating: "#", count: crossword.grid.width)
        var charGrid = [[Character]](repeating: charRow, count: crossword.grid.height)

        for (span, domain) in domains {
            guard domain.count == 1 else {
                fatalError("asString can be used after completion.")
            }

            let value = domain[0]
            for index in 0..<span.length {
                let x = span.start.x + span.direction.deltaX * index
                let y = span.start.y + span.direction.deltaY * index
                charGrid[y][x] = value[index]
            }
        }

        var result = ""
        for row in charGrid {
            for char in row {
                result.append(char)
            }
            result.append("\n")
        }
        return String(result.dropLast())
    }

}

// Initializers
extension DomainMap {

    private static func assign(mustWords: [Word], to domains: inout [Span: Domain]) -> Bool {
        let spans = domains.keys

        var mustWordSpans = Set<Span>()
        for mustWord in mustWords {
            // Find span that can have mustWord.
            let mustWordSpan = spans.first { span in
                !mustWordSpans.contains(span) && span.length == mustWord.count
            }

            guard let mustWordSpan else {
                // None of spans can have the must word. This
                // crossword puzzle does not have a solution.
                return false
            }

            domains[mustWordSpan] = Domain(for: mustWordSpan, using: [mustWord])
            mustWordSpans.insert(mustWordSpan)
        }
        return true
    }

    /// Creates CSP variables.
    ///
    /// - Parameters:
    ///  - crossword: The crossword to solve.
    ///  - lexicon: Set of words which the crossword puzzle would use.
    ///  - mustWords: List of words that must be used in the puzzle. It does not have to be in the lexicon.
    init?(
        crossword: Crossword,
        lexicon: [Word],
        mustWords: [Word] = []
    ) {
        let spans = crossword.spans
        let variables = spans.map { Domain(for: $0, using: lexicon) }
        guard variables.allSatisfy({ !$0.isEmpty }) else {
            // Some spans had odd length and none of the words in
            // lexicon can be assigned.
            return nil
        }

        var domains = Dictionary(uniqueKeysWithValues: zip(spans, variables))
        guard Self.assign(mustWords: mustWords, to: &domains) else {
            // Unable to assign must-words.
            return nil
        }

        self.crossword = crossword
        self.domains = domains
    }

    /// Creates CSP variables.
    ///
    /// It is a convenient initializer that takes String literals.
    ///
    /// - Parameters:
    ///  - crossword: The crossword to solve.
    ///  - lexicon: Set of words which the crossword puzzle would use.
    ///  - mustWords: List of words that must be used in the puzzle. It does not have to be in the lexicon.
    init?(
        crossword: Crossword,
        lexicon: [String],
        mustWords: [String] = []
    ) {
        self.init(
            crossword: crossword,
            lexicon: lexicon.map(Word.init),
            mustWords: mustWords.map(Word.init))
    }
}

// Status
extension DomainMap {
    var complete: Bool {
        domains.values.allSatisfy { domain in
            domain.count == 1
        }
    }

    var valid: Bool {
        domains.values.allSatisfy { domain in
            !domain.isEmpty
        }
    }
}

// mutating functions
extension DomainMap {
    mutating func update(span: Span, values: [Word]) {
        domains[span]!.update(to: values)
    }

    mutating func update(span: Span, remove word: Word) {
        domains[span]!.update(remove: word)
    }
}

extension DomainMap: CustomStringConvertible, CustomDebugStringConvertible {
    public var description: String {
        let count = domains.count
        let singleDomainCount = domains.count { (_, domain) in domain.count == 1 }
        let zeroDomainCount = domains.count { (_, domain) in domain.count == 0 }
        return
            "DomainMap(total = \(count), solved = \(singleDomainCount), failed = \(zeroDomainCount)"
    }

    public var debugDescription: String {
        var result = ""
        for (span, domain) in domains {
            result.append("\(span): \(domain)\n")
        }
        return result
    }
}
