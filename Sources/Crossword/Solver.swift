import Collections
import CryptoKit

public struct Solver {
    class VisitedSolutions {
        var visitedSet = Set<SHA256Digest>()
        func firstVisit(_ solution: Solution) -> Bool {
            let digest = solution.digest
            let (inserted, _) = visitedSet.insert(digest)
            return inserted
        }
    }

    let crossword: Crossword
    let lexicon: [Word]
    let mustWords: [Word]
    let visitedSolutions = VisitedSolutions()

    func enforceArcConsistencyInternal(
        solution: inout Solution,
        workQueue: inout Deque<SpanPair>
    ) -> Bool {
        var success = true
        while let spanPair = workQueue.popFirst() {
            let targetSpan = spanPair.span1
            let referenceSpan = spanPair.span2
            if solution.reduceArc(of: targetSpan, using: referenceSpan) {
                if solution.domain(for: targetSpan).isEmpty {
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

    func enforceArcConsistency(solution: inout Solution) -> Bool {
        var workQueue = Deque(crossword.overlaps.keys)
        return enforceArcConsistencyInternal(solution: &solution, workQueue: &workQueue)
    }

    func enforceArcConsistency(solution: inout Solution, span: Span) -> Bool {
        let workItems = crossword.spansIntersecting(with: span).map { SpanPair($0, span) }
        var workQueue = Deque(workItems)
        return enforceArcConsistencyInternal(solution: &solution, workQueue: &workQueue)
    }

    /// Enforce the rule: Crossword puzzle cannot use a same word
    /// multiple times.
    func enforceGlobalConsistency(solution: inout Solution) -> Bool {
        // For each word of any single-value domain, remove it from
        // the other domain.
        for referenceSpan in crossword.spans {
            let domain = solution.domain(for: referenceSpan)
            if domain.count != 1 {
                continue
            }

            let word = domain[0]
            // referenceSpan has been reduced to single value domain
            // and the word should be removed from other domains.
            solution.update(except: referenceSpan, remove: word)
        }

        return solution.solvable
    }

    func solveInternal(
        solution: Solution, stop: inout Bool,
        solutionReporter: (Solution, inout Bool) -> Void
    ) {
        guard visitedSolutions.firstVisit(solution) else {
            return
        }

        if solution.complete {
            solutionReporter(solution, &stop)
            if stop {
                return
            }
        }

        for span in solution.unsolvedSpans {
            if stop {
                return
            }

            let candidates = solution.domain(for: span)
            if candidates.count == 1 {
                continue
            }

            for value in candidates {
                if stop {
                    return
                }

                var newSolution = solution
                newSolution.update(span: span, values: [value])
                newSolution.update(except: span, remove: value)
                if !newSolution.solvable {
                    continue
                }

                if !enforceArcConsistency(solution: &newSolution, span: span) {
                    continue
                }

                solveInternal(
                    solution: newSolution, stop: &stop, solutionReporter: solutionReporter)
            }
        }
    }

    public func solve() -> [Solution] {
        guard
            var solution = Solution(
                crossword: crossword,
                lexicon: lexicon,
                mustWords: mustWords)
        else {
            return []
        }

        guard enforceGlobalConsistency(solution: &solution) else {
            return []
        }

        guard enforceArcConsistency(solution: &solution) else {
            return []
        }

        var solutions = [Solution]()
        var stop = false
        solveInternal(solution: solution, stop: &stop) { solution, stop in
            solutions.append(solution)
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
