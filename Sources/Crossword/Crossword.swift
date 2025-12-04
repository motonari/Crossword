/// Structure of the crossword puzzle.
public struct Crossword {
    let grid: Grid
    let spans: [Span]
    let layout: Layout
    let overlaps: [SpanPair: (Int, Int)]

    static func spanLength(
        at start: Location,
        direction: Direction,
        in grid: Grid,
        with layout: Layout
    ) -> Int {

        var length = 0
        var location = start
        while grid.contains(location) && layout.cell(at: location, in: grid) == .white {
            location += direction.delta
            length += 1
        }

        return length
    }

    static func spanStarts(
        at location: Location,
        direction: Direction,
        in grid: Grid,
        with layout: Layout
    )
        -> Bool
    {
        guard grid.contains(location) else {
            return false
        }

        guard layout.cell(at: location, in: grid) == .white else {
            return false
        }

        // Another span ("CAT") cannot share the span's ("DOG")
        // preceeding cell because "ADOG" is not a word.
        //
        //  C
        //  ADOG
        //  T
        //
        // It means the preceeding cell must be either:
        // 1. Outside of the grid.
        // 2. A black cell
        let preceedingLocation = location - direction.delta
        return !grid.contains(preceedingLocation)
            || layout.cell(at: preceedingLocation, in: grid) == .black
    }

    static func makeSpans(
        for grid: Grid,
        with layout: Layout
    ) -> [Span] {
        var spans = [Span]()

        for location in Locations(grid: grid) {
            if spanStarts(at: location, direction: .down, in: grid, with: layout) {
                let length = spanLength(
                    at: location,
                    direction: .down,
                    in: grid,
                    with: layout)

                if length >= 2 {
                    let placeholder = Span(at: location, length: length, direction: .down)
                    spans.append(placeholder)
                }
            }

            if spanStarts(at: location, direction: .across, in: grid, with: layout) {
                let length = spanLength(
                    at: location,
                    direction: .across,
                    in: grid,
                    with: layout)
                if length >= 2 {
                    let span = Span(at: location, length: length, direction: .across)
                    spans.append(span)
                }
            }
        }
        return spans
    }

    static func makeOverlaps(among spans: [Span])
        -> [SpanPair: (Int, Int)]
    {
        var result = [SpanPair: (Int, Int)]()
        for span1 in spans {
            for span2 in spans {
                if span1 == span2 {
                    continue
                }

                if let overlap = span1.intersects(with: span2) {
                    result[SpanPair(span1, span2)] = overlap
                }
            }
        }
        return result
    }

    func crossIndices(of spanPair: SpanPair) -> (Int, Int)? {
        overlaps[spanPair]
    }

    func spansIntersecting(with targetSpan: Span) -> [Span] {
        spans.filter { span in
            span.intersects(with: targetSpan) != nil
        }
    }

    func span(at start: Location, direction: Direction) -> Span? {
        spans.first { span in
            span.start == start && span.direction == direction
        }
    }

    public func hasLonelySpan() -> Bool {
        spans.contains { spansIntersecting(with: $0).isEmpty }
    }

    public var asString: String {
        let charRow = [Character](repeating: ":", count: grid.width)
        var charGrid = [[Character]](repeating: charRow, count: grid.height)

        for location in Locations(grid: grid) {
            if layout.cell(at: location, in: grid) == .black {
                charGrid[location.y][location.x] = "#"
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

// Initializers
extension Crossword {
    /// Creates with layout.
    public init(grid: Grid, with layout: Layout) {
        var spans = Self.makeSpans(for: grid, with: layout)
        let overlaps = Self.makeOverlaps(among: spans)

        spans.sort(by: { spanA, spanB in
            let intersectingCountA = overlaps.count(where: { spanPair, _ in
                spanPair.span1 == spanA
            })

            let intersectingCountB = overlaps.count(where: { spanPair, _ in
                spanPair.span1 == spanB
            })

            return intersectingCountA > intersectingCountB
        })

        self.grid = grid
        self.layout = layout
        self.spans = spans
        self.overlaps = overlaps
    }

    /// Creates with all white cells.
    public init(grid: Grid) {
        self.init(grid: grid, with: Layout(grid: grid))
    }
}
