import Collections

public struct Solver {
    let crossword: Crossword
    let lexicon: [Word]
    let mustWords: [Word]

    func enforceArcConsistencyInternal(
        domains: inout DomainMap,
        workQueue: inout Deque<SpanPair>
    ) -> Bool {
        var success = true
        while let spanPair = workQueue.popFirst() {
            let targetSpan = spanPair.span1
            let referenceSpan = spanPair.span2
            if domains.reduceArc(of: targetSpan, using: referenceSpan) {
                if domains.domain(for: targetSpan).isEmpty {
                    success = false
                    break
                } else {
                    for affectedSpan in crossword.spansIntersecting(with: targetSpan) {
                        workQueue.append(SpanPair(affectedSpan, targetSpan))
                    }
                }
            }
        }

        return success
    }

    func enforceArcConsistency(domains: inout DomainMap) -> Bool {
        var workQueue = Deque(crossword.overlaps.keys)
        return enforceArcConsistencyInternal(domains: &domains, workQueue: &workQueue)
    }

    func enforceArcConsistency(domains: inout DomainMap, span: Span) -> Bool {
        let workItems = crossword.spansIntersecting(with: span).map { SpanPair($0, span) }
        var workQueue = Deque(workItems)
        return enforceArcConsistencyInternal(domains: &domains, workQueue: &workQueue)
    }

    /// Enforce the rule: Crossword puzzle cannot use a same word
    /// multiple times.
    func enforceGlobalConsistency(domains: inout DomainMap) -> Bool {
        // For each word of any single-value domain, remove it from
        // the other domain.
        for referenceSpan in crossword.spans {
            let domain = domains.domain(for: referenceSpan)
            if domain.count != 1 {
                continue
            }

            let word = domain[0]
            // referenceSpan has been reduced to single value domain
            // and the word should be removed from other domains.
            for targetSpan in crossword.spans {
                if targetSpan == referenceSpan {
                    continue
                }

                domains.update(span: targetSpan, remove: word)
            }
        }

        return domains.valid
    }

    func solveInternal(
        domains: DomainMap, stop: inout Bool,
        solutionReporter: (DomainMap, inout Bool) -> Void
    ) {
        if domains.complete {
            solutionReporter(domains, &stop)
            if stop {
                return
            }
        }

        for span in crossword.spans {
            if stop {
                return
            }

            let candidates = domains.domain(for: span)
            if candidates.count == 1 {
                continue
            }

            for value in candidates {
                if stop {
                    return
                }

                var newDomains = domains
                newDomains.update(span: span, values: [value])
                if !enforceGlobalConsistency(domains: &newDomains) {
                    continue
                }

                if !enforceArcConsistency(domains: &newDomains, span: span) {
                    continue
                }

                solveInternal(domains: newDomains, stop: &stop, solutionReporter: solutionReporter)
            }
        }
    }

    public func solve() -> [String] {
        guard
            var domains = DomainMap(
                crossword: crossword,
                lexicon: lexicon,
                mustWords: mustWords)
        else {
            return []
        }

        guard enforceGlobalConsistency(domains: &domains) else {
            return []
        }

        guard enforceArcConsistency(domains: &domains) else {
            return []
        }

        var solutions = [String]()
        var stop = false
        solveInternal(domains: domains, stop: &stop) { solution, stop in
            solutions.append(solution.stringRepresentation)
            stop = (solutions.count > 0)
        }

        return solutions
    }

}

/// Initializers
extension Solver {
    /// Creates a solver.
    ///
    /// - Parameters:
    ///  - crossword: The crossword to solve.
    ///  - lexicon: Set of words that the crossword can use.
    ///  - mustWord: Set of words that the crossword must use.
    public init(for crossword: Crossword, lexicon: [Word], mustWords: [Word] = []) {
        self.crossword = crossword
        self.lexicon = lexicon
        self.mustWords = mustWords
    }
}
