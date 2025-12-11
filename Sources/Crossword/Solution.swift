import CryptoKit

// MARK: Structure
/// Set of CSP variables and their domains, which are possible values
/// for the variable.
///
/// Solution is complete if all the domains have one and only one
/// possible value.
public struct Solution {
    /// The crossword puzzle the solution is for.
    let crossword: Crossword

    /// Dictionary of span and its domain.
    private var domains: [Span: Domain]
}

// MARK: Initializers
extension Solution {
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
        guard
            let domains = Self.makeSpanDomainDictionary(
                crossword: crossword, lexicon: lexicon, mustWords: mustWords)
        else {
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

    /// Make the initial span to domain dictionary.
    ///
    /// - Parameters:
    ///  - crossword: The crossword to solve.
    ///  - lexicon: Set of words which the crossword puzzle would use.
    ///  - mustWords: List of words that must be used in the puzzle. It does not have to be in the lexicon.
    private static func makeSpanDomainDictionary(
        crossword: Crossword,
        lexicon: [Word],
        mustWords: [Word]
    )
        -> [Span: Domain]?
    {
        // Build span -> domain map using the lexicon.
        let spans = crossword.spans
        var domains = [Span: Domain](minimumCapacity: spans.count)

        var unassignedMustWords = mustWords
        for span in spans {
            // The default domain is a set of words in the lexicon.
            var values = lexicon

            // But if any must-word fits in the span, assign it here and call it a day.
            if let eligibleMustWordIndex = unassignedMustWords.firstIndex(where: { mustWord in
                mustWord.count == span.length
            }) {
                values = [unassignedMustWords[eligibleMustWordIndex]]
                unassignedMustWords.remove(at: eligibleMustWordIndex)
            }

            // Then, make Domain object.
            guard let domain = Domain(for: span, using: values) else {
                // The span length did not match any of the words in
                // lexicon.
                return nil
            }

            domains[span] = domain
        }

        if !unassignedMustWords.isEmpty {
            // Oops, some must-words were failed to get assigned.
            return nil
        }

        return domains
    }
}

// MARK: CSP algorithms
extension Solution {
    /// Reduce domain of `targetSpan` based on the domain of `referenceSpan`.
    ///
    /// This ensures arc-consistency between `targetSpan` and `referenceSpan`.
    ///
    /// - Returns: true if the domain has been modified.
    /// - Parameters:
    ///  - targetSpan: The function reduces the domain of this span.
    ///  - referenceSpan: The function uses this span as the reference.
    mutating func enforceArcConsistency(
        of targetSpan: Span,
        using referenceSpan: Span
    ) -> Bool {

        // Find the character indices at the intersection if any.
        guard
            let (targetCharIndex, referenceCharIndex) =
                crossword.crossIndices(of: SpanPair(targetSpan, referenceSpan))
        else {
            return false
        }

        let referenceDomain = domain(for: referenceSpan)

        // For each value in the target domain, check if it is
        // consistent with any value in the reference domain. If not,
        // remove it from the target domain.
        var validWords = [Word]()
        var changed = false
        for targetWord in domain(for: targetSpan) {
            // Do any values in the reference domain have a matching
            // character at the intersection?
            let crossChar = targetWord[targetCharIndex]
            let consistent = referenceDomain.contains(where: { referenceWord in
                referenceWord[referenceCharIndex] == crossChar
            })

            if consistent {
                validWords.append(targetWord)
            } else {
                // targetWord is removed; the domain has been changed.
                changed = true
            }
        }

        if changed {
            assign(words: validWords, to: targetSpan)
        }

        return changed
    }
}

// MARK: Status
extension Solution {
    /// The solution is complete.
    ///
    /// In other words, all the domains are reduced to one value.
    var complete: Bool {
        domains.values.allSatisfy { domain in
            domain.count == 1
        }
    }

    /// The solution is solvable.
    ///
    /// In other words, all the domains have some values.
    var solvable: Bool {
        domains.values.allSatisfy { domain in
            !domain.isEmpty
        }
    }

    /// List of unsolved spans.
    ///
    /// The solver tries to solve them with DFS. To reduce the tree
    /// size, sort the list from smaller domain to larger domain, with
    /// the expectation that the larger domain would be reduced
    /// quickly as DFS goes deeper.
    var unsolvedSpans: [Span] {
        crossword.spans.filter { span in
            domain(for: span).count > 1
        }.sorted { span1, span2 in
            let domainCount1 = domain(for: span1).count
            let domainCount2 = domain(for: span2).count
            return domainCount1 < domainCount2
        }
    }

    /// Domain of a specified span.
    ///
    /// We knew `domains` dictionary has all the spans anyway.
    func domain(for span: Span) -> Domain {
        domains[span]!
    }

}

// MARK: Digestable
extension Solution: Digestable {
    /// SHA256 hash for memorization in the dynamic programming
    /// optimization in DFS.
    var digest: SHA256.Digest {
        var hasher = SHA256()
        for span in crossword.spans {
            domains[span]!.hash(into: &hasher)
        }
        return hasher.finalize()
    }
}

// MARK: Mutating domains
extension Solution {
    mutating func assign(words: [Word], to span: Span) {
        domains[span]!.update(to: words)
    }

    mutating func assign(word: Word, to span: Span) {
        assign(words: [word], to: span)
    }

    mutating func remove(word: Word, from span: Span) -> (Bool, Int) {
        domains[span]!.remove(word)
    }
}

// MARK: String Representation
extension Solution: CustomStringConvertible, CustomDebugStringConvertible {
    /// Implementation of CustomStringConvertible
    public var description: String {
        let count = domains.count
        let singleDomainCount = domains.count { (_, domain) in domain.count == 1 }
        let zeroDomainCount = domains.count { (_, domain) in domain.count == 0 }
        return
            "DomainMap(total = \(count), solved = \(singleDomainCount), failed = \(zeroDomainCount)"
    }

    /// Implementation of CustomDebugStringConvertible
    public var debugDescription: String {
        var result = ""
        for (span, domain) in domains {
            result.append("\(span): \(domain)\n")
        }
        return result
    }

    /// Grid representation of the solution.
    ///
    /// Use this property to examine the solution for debugging.
    public var gridRepresentation: String {
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
