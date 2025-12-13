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
        let newLayouts = expandInternal(baseLayout)
        let sortedNewLayouts =
            newLayouts
            .shuffled()
            .sorted(by: { layout1, layout2 in
                let (intersectionCount1, _) = layout1.score
                let (intersectionCount2, _) = layout2.score
                return intersectionCount1 >= intersectionCount2
            })
            .prefix(beamWidth)

        for newLayout in sortedNewLayouts {
            if visitLog.firstVisit(fingerprint(of: newLayout)) {
                workQueue.prepend(newLayout)
            }
        }
    }

    private func fingerprint(of layout: Layout) -> [UInt8] {
        return layout.storage
    }

    private func expandInternal(_ layout: Layout) -> [Layout] {
        var candidates = [Layout]()
        let spans = layout.spans
        let edgeSet = makeEdgeSet(spans: spans)
        let blackSet = Set(layout.blackCells())

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

                guard !spans.contains(where: { $0.start == location && $0.direction == direction })
                else {
                    continue
                }

                for length in (minWordLength...maxLength) {
                    let newSpan = Span(at: location, length: length, direction: direction)
                    guard
                        edgeSet.contains(newSpan.firstEdge) || blackSet.contains(newSpan.firstEdge)
                    else {
                        // Optimization. If `newSpan`'s start is not
                        // compatible with an existing span, it won't
                        // be compatible if we extend the length of
                        // it.
                        break
                    }

                    guard edgeSet.contains(newSpan.lastEdge) || blackSet.contains(newSpan.lastEdge)
                    else {
                        continue
                    }

                    guard
                        edgeSet.allSatisfy({
                            !(newSpan.rangeX.contains($0.x) && newSpan.rangeY.contains($0.y))
                        })
                    else {
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

                    var newLayout = layout
                    newLayout.insert(newSpan)

                    candidates.append(newLayout)
                }
            }
        }

        return candidates
    }

    private func makeEdgeSet(spans: [Span]) -> Set<Location> {
        var edges = Set<Location>()
        for span in spans {
            edges.insert(span.firstEdge)
            edges.insert(span.lastEdge)
        }

        for x in -1...grid.width {
            edges.insert(Location(x, -1))
            edges.insert(Location(x, grid.height))
        }

        for y in -1...grid.height {
            edges.insert(Location(-1, y))
            edges.insert(Location(grid.width, y))
        }
        return edges
    }
}
