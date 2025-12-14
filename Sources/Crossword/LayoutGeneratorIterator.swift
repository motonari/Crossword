import Collections
import CryptoKit
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
        layout.storage
    }

    private func expandInternal(_ layout: Layout) -> [Layout] {
        var candidates = [Layout]()
        let spans = layout.spans
        let blackSet = layout.blackCells()
        let edgeSet = makeEdgeSet(spans: spans)

        for y in 0..<grid.height {
            candidates.append(
                contentsOf: findLayout(
                    baseLayout: layout,
                    rowOrColumn: y,
                    direction: .across,
                    spans: spans,
                    blackSet: blackSet,
                    edgeSet: edgeSet)
            )
        }

        for x in 0..<grid.width {
            candidates.append(
                contentsOf: findLayout(
                    baseLayout: layout,
                    rowOrColumn: x,
                    direction: .down,
                    spans: spans,
                    blackSet: blackSet,
                    edgeSet: edgeSet)
            )
        }

        return candidates
    }

    private func findLayout(
        baseLayout: Layout,
        rowOrColumn: Int,
        direction: Direction,
        spans: [Span],
        blackSet: [Location],
        edgeSet: [Location]
    ) -> [Layout] {
        var candidates = [Layout]()
        let filter = makeBlockingCellFilter(direction: direction, rowOrColumn: rowOrColumn)
        var filteredBlackSet = Set<Location>(minimumCapacity: blackSet.count)
        var filteredEdgeSet = Set<Location>(minimumCapacity: edgeSet.count)

        for item in blackSet {
            if filter(item) {
                filteredBlackSet.insert(item)
            }
        }

        for item in edgeSet {
            if filter(item) {
                filteredEdgeSet.insert(item)
            }
        }

        let maxStartIndex = direction == .across ? grid.width : grid.height

        for startIndex in 0..<maxStartIndex {
            let maxLength = maxSpanLength(from: startIndex, direction: direction)
            if maxLength < minWordLength {
                break
            }

            let location = spanStartLocation(
                movingIndex: startIndex, fixedIndex: rowOrColumn, for: direction)
            guard !spans.contains(where: { $0.start == location && $0.direction == direction })
            else {
                continue
            }

            for length in (minWordLength...maxLength) {
                let firstEdge = location - direction.delta
                guard
                    filteredEdgeSet.contains(firstEdge) || filteredBlackSet.contains(firstEdge)
                else {
                    // Optimization. If `newSpan`'s start is not
                    // compatible with an existing span, it won't
                    // be compatible if we extend the length of
                    // it.
                    break
                }

                let lastEdge: Location = spanEndLocation(
                    start: location, length: length, direction: direction)

                guard filteredEdgeSet.contains(lastEdge) || filteredBlackSet.contains(lastEdge)
                else {
                    continue
                }

                let newSpan = Span(at: location, length: length, direction: direction)
                guard
                    filteredEdgeSet.allSatisfy({
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

                var newLayout = baseLayout
                newLayout.insert(newSpan)

                candidates.append(newLayout)
            }
        }
        return candidates
    }

    private func maxSpanLength(from index: Int, direction: Direction) -> Int {
        let result =
            if direction == .across {
                grid.width - index
            } else {
                grid.height - index
            }
        return result
    }

    private func spanStartLocation(movingIndex: Int, fixedIndex: Int, for direction: Direction)
        -> Location
    {
        return if direction == .across {
            Location(movingIndex, fixedIndex)
        } else {
            Location(fixedIndex, movingIndex)
        }
    }

    private func spanEndLocation(start: Location, length: Int, direction: Direction) -> Location {
        return Location(
            start.x + direction.deltaX * length,
            start.y + direction.deltaY * length)
    }

    private func makeBlockingCellFilter(
        direction: Direction,
        rowOrColumn: Int
    ) -> (Location) -> Bool {
        if direction == .across {
            return { $0.y == rowOrColumn }
        } else {
            return { $0.x == rowOrColumn }
        }
    }

    private func makeEdgeSet(
        spans: [Span]
    ) -> [Location] {
        var edges = [Location]()
        for span in spans {
            edges.append(span.firstEdge)
            edges.append(span.lastEdge)
        }

        for y in -1...grid.height {
            edges.append(Location(-1, y))
            edges.append(Location(grid.width, y))
        }

        for x in -1...grid.width {
            edges.append(Location(x, -1))
            edges.append(Location(x, grid.height))
        }

        return edges
    }
}
