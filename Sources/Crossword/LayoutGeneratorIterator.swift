import Collections
import CryptoKit

// MARK: Structure

/// The iterator to generate layouts
struct LayoutGeneratorIterator {
    typealias SpanSet = TreeSet<Span>
    let grid: Grid
    let wordCount: Int
    let minWordLength: Int
    let beamWidth: Int

    private var workQueue = Deque<SpanSet>()
    private let visitLog = SearchLog<SpanSet>()
}

// MARK: Initializers
extension LayoutGeneratorIterator {
    init(grid: Grid, wordCount: Int, minWordLength: Int, beamWidth: Int) {
        self.grid = grid
        self.wordCount = wordCount
        self.minWordLength = minWordLength
        self.beamWidth = beamWidth
        self.workQueue.prepend(SpanSet([]))
    }
}

// MARK: IteratorProtocol
extension LayoutGeneratorIterator: IteratorProtocol {
    mutating func next() -> Layout? {
        while true {
            guard let workItem = workQueue.popFirst() else {
                // End of search
                return nil
            }

            if workItem.count == wordCount {
                // Search completed.
                return blackCells(spans: workItem)
            } else {
                expand(workItem)
            }
        }
    }

    private mutating func expand(_ baseLayout: SpanSet) {
        let nextSpans = baseLayout.nextSpans(
            grid: grid,
            minWordLength: minWordLength,
            beamWidth: beamWidth)

        for span in nextSpans {
            let newLayout = baseLayout.union([span])
            if visitLog.firstVisit(newLayout) {
                workQueue.prepend(newLayout)
            }
        }
    }

    private func blackCells(spans: SpanSet) -> Layout {
        var blackCells = [Location]()
        for location in Locations(grid: grid) {
            let useBlackCell = spans.allSatisfy { span in
                let (xRange, yRange) = span.range
                return !xRange.contains(location.x) || !yRange.contains(location.y)
            }

            if useBlackCell {
                blackCells.append(location)
            }
        }
        return Layout(grid: grid, blackCells: blackCells)
    }
}

extension TreeSet where Element == Span {
    fileprivate func nextSpans(
        grid: Grid,
        minWordLength: Int,
        beamWidth: Int
    ) -> [Span] {
        var candidates = [(Int, Span)]()
        let spans = Array(self)

        for direction in Direction.allCases {
            for location in Locations(grid: grid) {
                let maxLength =
                    if direction == .across {
                        grid.width - location.x
                    } else {
                        grid.height - location.y
                    }

                if maxLength < minWordLength {
                    continue
                }

                for length in (minWordLength...maxLength) {
                    let newSpan = Span(at: location, length: length, direction: direction)

                    guard spans.allSatisfy({ newSpan.compatibleStart(with: $0) }) else {
                        // Optimization. If `newSpan`'s start is not
                        // compatible with an existing span, it won't
                        // be compatible if we extend the length of
                        // it.
                        break
                    }

                    guard spans.allSatisfy({ newSpan.compatible(with: $0) }) else {
                        continue
                    }

                    guard
                        !spans.contains(where: {
                            newSpan.adjoining(with: $0)
                        })
                    else {
                        continue
                    }

                    let score = spans.count {
                        newSpan.intersects(with: $0) != nil
                    }

                    guard spans.count == 0 || score > 0 else {
                        // A new span must intersects with at least
                        // one existing span, if such a span exists.
                        continue
                    }

                    candidates.append((score, newSpan))
                }
            }
        }

        return
            candidates
            .shuffled()
            .sorted(by: { $0.0 > $1.0 })
            .prefix(beamWidth).map { $0.1 }
    }

}

extension TreeSet: Digestable where Element == Span {
    var digest: SHA256.Digest {
        var hasher = SHA256()
        for span in self.sorted() {
            span.hash(into: &hasher)
        }
        return hasher.finalize()
    }
}
