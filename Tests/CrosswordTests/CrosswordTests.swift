import Testing

@testable import Crossword

@Suite struct CrosswordTests {
    @Test func twoOverlappingSpans() throws {
        // :##
        // :::
        // :##
        let grid = Grid(width: 3, height: 3)
        let blackCellLayout = Layout(grid: grid, blackCells: [(1, 0), (2, 0), (1, 2), (2, 2)])
        let crossword = Crossword(grid: grid, with: blackCellLayout)

        try #require(crossword.spans.count == 2)
        let span1 = try #require(crossword.span(at: Location(0, 1), direction: .across))
        let span2 = try #require(crossword.span(at: Location(0, 0), direction: .down))

        let crossIndices = try #require(crossword.crossIndices(of: SpanPair(span1, span2)))
        #expect(crossIndices == (0, 1))
    }
}
