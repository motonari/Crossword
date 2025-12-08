import Collections
import CryptoKit

public struct Solver {
    private let crossword: Crossword
    private let lexicon: [Word]
    private let mustWords: [Word]
    private let visitedSolutions = VisitedSolutions()
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

/// Arc-Consistency
extension Solver {
    /// Reduce all the domains per arc-consistency.
    ///
    /// - Parameters:
    ///  - solution: The solution to update.
    ///
    /// - Returns:
    ///  True if the solution is solvable, otherwise false.
    func enforceArcConsistency(solution: inout Solution) -> Bool {
        var workQueue = Deque(crossword.overlaps.keys)
        return enforceArcConsistencyInternal(solution: &solution, workQueue: &workQueue)
    }

    /// Reduce domains of spans that depend on a specified span.
    ///
    /// - Parameters:
    ///  - solution: The solution to update.
    ///  - span: The span which was updated. Any span that intersects
    ///  with this span will be updated according to arc-consistency.
    ///
    /// - Returns:
    ///  True if the solution is solvable, otherwise false.
    func enforceArcConsistency(solution: inout Solution, span: Span) -> Bool {
        let workItems = crossword.spansIntersecting(with: span).map { SpanPair($0, span) }
        var workQueue = Deque(workItems)
        return enforceArcConsistencyInternal(solution: &solution, workQueue: &workQueue)
    }

    private func enforceArcConsistencyInternal(
        solution: inout Solution,
        workQueue: inout Deque<SpanPair>
    ) -> Bool {
        // AC-3 algorithm.
        var success = true
        while let spanPair = workQueue.popFirst() {
            let targetSpan = spanPair.span1
            let referenceSpan = spanPair.span2
            if solution.enforceArcConsistency(of: targetSpan, using: referenceSpan) {
                let newDomain = solution.domain(for: targetSpan)
                if newDomain.isEmpty {
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

}

/// Global-Consistency
extension Solver {
    /// Enforce the rule that Crossword puzzle cannot use a same word
    /// multiple times.
    ///
    /// This function made the whole solution globally consistent.
    func enforceGlobalConsistency(solution: inout Solution) -> Bool {
        var workQueue = Deque<SpanPair>()

        for referenceSpan in crossword.spans {
            let newWorkItems = globalConsistencyWorkItems(of: solution, for: referenceSpan)
            workQueue.append(contentsOf: newWorkItems)
        }

        return enforceGlobalConsistencyInternal(solution: &solution, workQueue: &workQueue)
    }
    /// Enforce the rule: Crossword puzzle cannot use a same word
    /// multiple times.
    ///
    /// This function made dependent spans globally consistent, given
    /// the span that has been assigned a single value.
    func enforceGlobalConsistency(solution: inout Solution, span referenceSpan: Span) -> Bool {
        let newWorkItems = globalConsistencyWorkItems(of: solution, for: referenceSpan)
        var workQueue = Deque<SpanPair>(newWorkItems)
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
            guard solution.domain(for: targetSpan).count > 1 else { continue }
            workItems.append(SpanPair(targetSpan, referenceSpan))
        }
        return workItems
    }

    private func enforceGlobalConsistencyInternal(
        solution: inout Solution,
        workQueue: inout Deque<SpanPair>
    ) -> Bool {
        var success = true
        while let spanPair = workQueue.popFirst() {
            let targetSpan = spanPair.span1
            let referenceSpan = spanPair.span2

            let referenceDomain = solution.domain(for: referenceSpan)
            guard referenceDomain.count == 1 else {
                continue
            }

            let changed = solution.remove(word: referenceDomain[0], from: targetSpan)
            let newTargetDomain = solution.domain(for: targetSpan)
            if newTargetDomain.isEmpty {
                success = false
                break
            }

            if changed {
                let newWorkItems = globalConsistencyWorkItems(of: solution, for: targetSpan)
                workQueue.append(contentsOf: newWorkItems)
            }
        }
        return success
    }
}

/// Backtracking
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

        guard enforceGlobalConsistency(solution: &solution) else {
            return
        }

        guard enforceArcConsistency(solution: &solution) else {
            return
        }

        var stop = false
        try solveInternal(
            consistentSolution: solution,
            stop: &stop,
            solutionReporter: solutionReporter)
    }

    private func solveInternalByAssigningValue(
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
            if !enforceGlobalConsistency(solution: &newSolution, span: span) {
                continue
            }

            if !enforceArcConsistency(solution: &newSolution, span: span) {
                continue
            }

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
        guard visitedSolutions.firstVisit(solution) else {
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
            try solveInternalByAssigningValue(
                to: span,
                consistentSolution: solution,
                stop: &stop,
                solutionReporter: solutionReporter)
        }
    }

}

private class VisitedSolutions {
    var visitedSet = Set<SHA256Digest>()
    func firstVisit(_ solution: Solution) -> Bool {
        let digest = solution.digest
        let (inserted, _) = visitedSet.insert(digest)
        return inserted
    }
}
