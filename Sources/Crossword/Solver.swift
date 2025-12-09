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
        let seed = UInt64(abs(mustWords.reduce(1) { $0 ^ $1.hashValue }))
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
            var solution = Solution(
                crossword: crossword,
                lexicon: lexicon,
                mustWords: mustWords)
        else {
            return
        }

        enforceConsistency(solution: &solution)
        if !solution.solvable {
            return
        }

        var stop = false
        try solveInternal(
            consistentSolution: solution,
            stop: &stop,
            solutionReporter: solutionReporter)
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
        var workQueue = Deque(crossword.overlaps.keys)
        return enforceArcConsistencyInternal(solution: &solution, workQueue: &workQueue)
    }

    private func enforceArcConsistencyInternal(
        solution: inout Solution,
        workQueue: inout Deque<SpanPair>
    ) -> Bool {
        // AC-3 algorithm.
        var changed = false
        while let spanPair = workQueue.popFirst() {
            let targetSpan = spanPair.span1
            let referenceSpan = spanPair.span2
            if solution.enforceArcConsistency(of: targetSpan, using: referenceSpan) {
                changed = true
                let newDomain = solution.domain(for: targetSpan)
                if newDomain.isEmpty {
                    break
                } else {
                    for affectedSpan in crossword.spansIntersecting(with: targetSpan) {
                        workQueue.append(SpanPair(affectedSpan, targetSpan))
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
        var workQueue = Deque<SpanPair>()

        for referenceSpan in crossword.spans {
            let newWorkItems = globalConsistencyWorkItems(of: solution, for: referenceSpan)
            workQueue.append(contentsOf: newWorkItems)
        }

        return enforceGlobalConsistencyInternal(solution: &solution, workQueue: &workQueue)
    }

    private func globalConsistencyWorkItems(of solution: Solution, for referenceSpan: Span)
        -> [SpanPair]
    {
        var workItems = [SpanPair]()

        let referenceDomain = solution.domain(for: referenceSpan)
        guard referenceDomain.count == 1 else {
            return []
        }

        for targetSpan in crossword.spans {
            guard referenceSpan != targetSpan else { continue }
            workItems.append(SpanPair(targetSpan, referenceSpan))
        }
        return workItems
    }

    private func enforceGlobalConsistencyInternal(
        solution: inout Solution,
        workQueue: inout Deque<SpanPair>
    ) -> Bool {
        var anyDomainChanged = false
        while let spanPair = workQueue.popFirst() {
            let targetSpan = spanPair.span1
            let referenceSpan = spanPair.span2

            let referenceDomain = solution.domain(for: referenceSpan)
            guard referenceDomain.count == 1 else {
                continue
            }

            let changed = solution.remove(word: referenceDomain[0], from: targetSpan)
            if changed {
                anyDomainChanged = true
                let newWorkItems = globalConsistencyWorkItems(of: solution, for: targetSpan)
                workQueue.append(contentsOf: newWorkItems)
            }

            let newTargetDomain = solution.domain(for: targetSpan)
            if newTargetDomain.isEmpty {
                break
            }
        }
        return anyDomainChanged
    }
}
