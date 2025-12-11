import Collections
import CryptoKit

// MARK: Struct

/// Crossword CSP Solver
///
///
public struct Solver {
    private let crossword: Crossword
    private let lexicon: [Word]
    private let mustWords: [Word]
    private let visitLog = SearchLog<Solution>()
}

// MARK: Initializers
extension Solver {
    /// Creates a solver.
    ///
    /// - Parameters:
    ///  - crossword: The crossword to solve.
    ///  - lexicon: Set of words that the crossword can use.
    ///  - mustWord: Set of words that the crossword must use.
    public init(for crossword: Crossword, lexicon: [Word], mustWords: [Word] = []) {
        let signature = mustWords.reduce(1) { $0 ^ $1.stableHashValue }
        let seed = UInt64(abs(signature))
        var rng = SplitMix64(seed: seed)
        self.crossword = crossword
        self.lexicon = lexicon.shuffled(using: &rng)
        self.mustWords = mustWords
    }
}

// MARK: Backtracking Solver
extension Solver {
    /// Solve the crossword.
    public func solve(solutionReporter: (Solution, inout Bool) throws -> Void) throws {
        guard
            let solution = Solution(
                crossword: crossword,
                lexicon: lexicon)
        else {
            return
        }

        try solveMustWords(solution: solution) { mustWordsAssignment, stop in
            var newSolution = solution
            for (span, word) in mustWordsAssignment {
                newSolution.assign(word: word, to: span)
            }

            enforceConsistency(solution: &newSolution)
            if !newSolution.solvable {
                return
            }

            try solveInternal(
                consistentSolution: newSolution,
                stop: &stop,
                solutionReporter: solutionReporter)
        }
    }

    private func solveMustWords(
        solution: Solution, reporter: ([Span: Word], inout Bool) throws -> Void
    ) throws {
        var stop = false
        try solveMustWordsInternal(
            solution: solution,
            assignments: [Span: Word](),
            stop: &stop,
            reporter: reporter)
    }

    private func solveMustWordsInternal(
        solution: Solution,
        assignments: [Span: Word],
        stop: inout Bool,
        reporter: ([Span: Word], inout Bool) throws -> Void
    ) throws {
        if assignments.count == mustWords.count {
            // complete.
            try reporter(assignments, &stop)
            return
        }

        for span in solution.unsolvedSpans {
            guard !assignments.keys.contains(span) else {
                // This span has gotten one of the must words.
                continue
            }

            for mustWord in mustWords {
                guard !assignments.values.contains(mustWord) else {
                    // This word has been assigned.
                    continue
                }

                guard span.length == mustWord.count else {
                    // Length differs; we cannot assign the word to this span.
                    continue
                }

                var newAssignments = assignments
                newAssignments[span] = mustWord
                try solveMustWordsInternal(
                    solution: solution,
                    assignments: newAssignments,
                    stop: &stop,
                    reporter: reporter)
                if stop {
                    return
                }
            }
        }
    }

    private func enforceConsistency(solution: inout Solution) {
        var changed = true
        while changed && solution.solvable {
            changed = false
            if enforceGlobalConsistency(solution: &solution) {
                changed = true
            }

            if enforceArcConsistency(solution: &solution) {
                changed = true
            }
        }
    }

    private func assignValue(
        to span: Span,
        consistentSolution solution: Solution,
        stop: inout Bool,
        solutionReporter: (Solution, inout Bool) throws -> Void
    ) throws {
        let candidates = solution.domain(for: span)
        guard candidates.count > 1 else {
            return
        }

        for value in candidates {
            var newSolution = solution

            newSolution.assign(word: value, to: span)
            enforceConsistency(solution: &newSolution)
            if !newSolution.solvable {
                continue
            }

            try solveInternal(
                consistentSolution: newSolution,
                stop: &stop,
                solutionReporter: solutionReporter)
            if stop {
                return
            }
        }

    }

    private func solveInternal(
        consistentSolution solution: Solution,
        stop: inout Bool,
        solutionReporter: (Solution, inout Bool) throws -> Void
    ) throws {
        // Optimization by memorization. If we have seen this solution
        // before, we don't have to process it again.
        guard visitLog.firstVisit(solution) else {
            return
        }

        if solution.complete {
            // Solution is completed; report it!
            try solutionReporter(solution, &stop)
            if stop {
                return
            }
        }

        for span in solution.unsolvedSpans {
            try assignValue(
                to: span,
                consistentSolution: solution,
                stop: &stop,
                solutionReporter: solutionReporter)
            if stop {
                return
            }
        }
    }
}

// MARK: Arc-Consistency
extension Solver {
    /// Reduce all the domains per arc-consistency.
    ///
    /// - Parameters:
    ///  - solution: The solution to update.
    ///
    /// - Returns:
    ///  True if the domain has been modified.
    func enforceArcConsistency(solution: inout Solution) -> Bool {
        var workSet = Set(crossword.overlaps.keys)
        return enforceArcConsistencyInternal(solution: &solution, workSet: &workSet)
    }

    private func enforceArcConsistencyInternal(
        solution: inout Solution,
        workSet: inout Set<SpanPair>
    ) -> Bool {
        // AC-3 algorithm.
        var changed = false
        while !workSet.isEmpty {
            let spanPair = workSet.removeFirst()
            let targetSpan = spanPair.span1
            let referenceSpan = spanPair.span2
            if solution.enforceArcConsistency(of: targetSpan, using: referenceSpan) {
                changed = true
                let newDomain = solution.domain(for: targetSpan)
                if newDomain.isEmpty {
                    break
                } else {
                    for affectedSpan in crossword.spansIntersecting(with: targetSpan) {
                        workSet.insert(SpanPair(affectedSpan, targetSpan))
                    }
                }
            }
        }

        return changed
    }

}

// MARK: Global-Consistency
extension Solver {
    /// Enforce the rule that Crossword puzzle cannot use a same word
    /// multiple times.
    ///
    /// This function made the whole solution globally consistent.
    ///
    /// - Parameters:
    ///  - solution: The solution to update.
    ///
    /// - Returns:
    ///  True if the domain has been modified.
    func enforceGlobalConsistency(solution: inout Solution) -> Bool {
        var anyDomainChanged = false
        for referenceSpan in crossword.spans {
            let referenceDomain = solution.domain(for: referenceSpan)
            guard referenceDomain.count == 1 else {
                continue
            }

            let changed = enforceGlobalConsistencyInternal(
                solution: &solution,
                referenceSpan: referenceSpan,
                wordToRemove: referenceDomain[0])

            if changed {
                anyDomainChanged = true
            }
        }

        return anyDomainChanged
    }

    private func enforceGlobalConsistencyInternal(
        solution: inout Solution,
        referenceSpan: Span,
        wordToRemove: Word
    ) -> Bool {
        var anyDomainChanged = false

        for targetSpan in crossword.spans {
            guard referenceSpan != targetSpan else { continue }

            let (changed, remaining) = solution.remove(word: wordToRemove, from: targetSpan)
            if changed {
                anyDomainChanged = true

                if remaining == 1 {
                    let newDomain = solution.domain(for: targetSpan)
                    _ = enforceGlobalConsistencyInternal(
                        solution: &solution,
                        referenceSpan: targetSpan,
                        wordToRemove: newDomain[0])
                }
            }
        }

        return anyDomainChanged
    }
}
