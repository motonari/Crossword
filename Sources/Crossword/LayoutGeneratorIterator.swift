import Collections
import Foundation

// MARK: Structure

/// The iterator to generate layouts
struct LayoutGeneratorIterator {
    let grid: Grid
    let wordCount: Int
    let minWordLength: Int
    let beamWidth: Int

    private var workQueue = Deque<Layout>()
    private let visitLog = SearchLog<[UInt8]>()
}

// MARK: Initializers
extension LayoutGeneratorIterator {
    init(grid: Grid, wordCount: Int, minWordLength: Int, beamWidth: Int) {
        self.grid = grid
        self.wordCount = wordCount
        self.minWordLength = minWordLength
        self.beamWidth = beamWidth
        self.workQueue.prepend(Layout(grid: grid, filling: .black))
    }
}

// MARK: IteratorProtocol
extension LayoutGeneratorIterator: IteratorProtocol {
    mutating func next() -> Layout? {
        while true {
            guard let layout = workQueue.popFirst() else {
                // End of search
                return nil
            }

            if layout.spans.count == wordCount {
                // Search completed.
                return layout
            } else {
                expand(layout)
            }
        }
    }

    private mutating func expand(_ baseLayout: Layout) {
        let newSpans = expandInternal(baseLayout)
        for newSpan in newSpans {
            var newLayout = baseLayout
            newLayout.insert(newSpan)
            if visitLog.firstVisit(fingerprint(of: newLayout)) {
                workQueue.prepend(newLayout)
            }
        }
    }

    private func fingerprint(of layout: Layout) -> [UInt8] {
        return Array(layout.dataRepresentation)
    }

    private func expandInternal(_ layout: Layout) -> [Span] {
        var candidates = [(Int, Span)]()
        let spans = layout.spans

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
            .sorted(by: { $0.0 >= $1.0 })
            .prefix(beamWidth).map { $0.1 }
    }
}
