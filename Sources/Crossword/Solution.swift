import CryptoKit

/// Set of CSP variables and their domains.
///
/// Solution is complete if all the domains have one and only one possible value.
public struct Solution {
    let crossword: Crossword
    var domains: [Span: Domain]
}

// Initializers
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
        var domains = [Span: Domain]()

        var unassignedMustWords = Set(mustWords)
        for span in spans {
            var values = [Word]()

            // Try to assign a mustWord to this span.
            for mustWord in unassignedMustWords {
                if mustWord.count == span.length {
                    values.append(mustWord)
                    break
                }
            }

            if let mustWord = values.first {
                // mustWord will be assigned to the span.
                unassignedMustWords.remove(mustWord)
            } else {
                // No mustWord has compatible length with the span. We
                // assign the whole lexion to the span.
                values = lexicon
            }

            guard let domain = Domain(for: span, using: values) else {
                // The span length did not match any of the words in
                // lexicon.
                return nil
            }

            domains[span] = domain
        }

        return domains
    }
}

// CSP algorithms
extension Solution {
    /// Reduce domain of `targetSpan` based on the domain of `referenceSpan`.
    ///
    /// This ensures arc-consistency between `targetSpan` and `referenceSpan`.
    ///
    /// - Returns: true if the domain has been modified.
    /// - Parameters:
    ///  - targetSpan: The function reduces the domain of this span.
    ///  - referenceSpan: The function uses this span as the reference.
    mutating func reduceDomain(
        of targetSpan: Span,
        using referenceSpan: Span
    ) -> Bool {

        // Find the character indices of the intersection if any.
        guard
            let (targetCharIndex, referenceCharIndex) =
                crossword.crossIndices(of: SpanPair(targetSpan, referenceSpan))
        else {
            return false
        }

        let referenceDomain = domain(for: referenceSpan)

        var validWords = [Word]()
        var changed = false
        for targetWord in domain(for: targetSpan) {
            let overlapCharacter = targetWord[targetCharIndex]
            let valid = referenceDomain.contains(where: { referenceWord in
                referenceWord[referenceCharIndex] == overlapCharacter
            })

            if valid {
                validWords.append(targetWord)
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
            assign(words: validWords, to: targetSpan)
        }

        return changed
    }
}

// Status
extension Solution {
    var complete: Bool {
        domains.values.allSatisfy { domain in
            domain.count == 1
        }
    }

    var solvable: Bool {
        domains.values.allSatisfy { domain in
            !domain.isEmpty
        }
    }
}

// mutating functions
extension Solution {
    mutating func assign(words: [Word], to span: Span) {
        domains[span]!.update(to: words)
    }

    mutating func remove(word: Word, from span: Span) {
        domains[span]!.update(remove: word)
    }

    mutating func assign(word: Word, to span: Span) {
        assign(words: [word], to: span)
        remove(word: word, fromAllSpanExcept: span)
    }

    mutating func remove(word: Word, fromAllSpanExcept spanNotToUpdate: Span) {
        let savedDomain = domains[spanNotToUpdate]!
        for index in domains.values.indices {
            domains.values[index].update(remove: word)
        }
        domains[spanNotToUpdate] = savedDomain
    }
}

extension Solution {
    /// List of unsolved spans.
    var unsolvedSpans: [Span] {
        crossword.spans.filter { span in
            domain(for: span).count > 1
        }.sorted { span1, span2 in
            let domainCount1 = domain(for: span1).count
            let domainCount2 = domain(for: span2).count
            return domainCount1 < domainCount2
        }
    }

    func domain(for span: Span) -> Domain {
        domains[span]!
    }
}

extension Solution {
    var digest: SHA256.Digest {
        var hasher = SHA256()
        for span in crossword.spans {
            domains[span]!.hash(into: &hasher)
        }
        return hasher.finalize()
    }
}

extension Solution: CustomStringConvertible, CustomDebugStringConvertible {
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

    var gridRepresentation: String {
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
