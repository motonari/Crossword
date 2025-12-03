import Testing

@testable import Crossword

@Suite struct DomainMapTests {
    @Test func initialization() throws {
        // :::
        // :#:
        // :::
        let grid = Grid(width: 3, height: 3)
        let layout = Layout(grid: grid, blackCells: [(1, 1)])
        let crossword = Crossword(grid: grid, with: layout)
        let wordList = ["CAT", "DOG"]
        let domainMap = try #require(DomainMap(crossword: crossword, lexicon: wordList))

        // Every span should have domain: "CAT" and "DOG"
        for span in crossword.spans {
            #expect(domainMap.values(for: span) == wordList)
        }
    }

    @Test func nodeInconsistency() throws {
        let grid = Grid(width: 4, height: 1)
        let crossword = Crossword(grid: grid)
        let wordList = ["CAT", "DOG"]

        #expect(
            DomainMap(crossword: crossword, lexicon: wordList) == nil,
            "Neither CAT or DOG fits in 4-letter span; the initializer should fail.")
    }

    @Test func reduceArc1() throws {
        // :##
        // :::
        // :##
        let grid = Grid(width: 3, height: 3)
        let layout = Layout(grid: grid, blackCells: [(1, 0), (2, 0), (1, 2), (2, 2)])
        let crossword = Crossword(grid: grid, with: layout)

        let span1 = crossword.span(at: Location(0, 1), direction: .across)!
        let span2 = crossword.span(at: Location(0, 0), direction: .down)!

        let wordList = ["CAT", "DOG", "OWL"]
        var domainMap = try #require(DomainMap(crossword: crossword, lexicon: wordList))

        #expect(domainMap.reduceArc(of: span1, using: span2) == true)

        // span2's domain is ["CAT", "DOG", "OWL"]. It overlaps with
        // span1 at the letter 'O'. So, the reduced domain for span1
        // should be just ["OWL"].

        #expect(domainMap.values(for: span1) == ["OWL"])
    }
}
