import Testing

@testable import Crossword

@Suite struct SolutionTests {
    @Test func initialization() throws {
        // :::
        // :#:
        // :::
        let grid = Grid(width: 3, height: 3)
        let layout = Layout(grid: grid, blackCells: [(1, 1)])
        let crossword = Crossword(grid: grid, with: layout)
        let wordList = ["CAT", "DOG"]
        let solution = try #require(Solution(crossword: crossword, lexicon: wordList))

        // Every span should have domain: "CAT" and "DOG"
        for span in crossword.spans {
            #expect(solution.domain(for: span).stringArrayRepresentation == wordList)
        }
    }

    @Test func initWithMustWord() throws {
        // :::
        // ###
        // :::
        let grid = Grid(width: 3, height: 3)
        let layout = Layout(
            grid: grid,
            blackCells: [
                (0, 1),
                (1, 1),
                (2, 1),
            ])

        let crossword = Crossword(grid: grid, with: layout)
        let wordList = ["CAT", "DOG"]
        let solution = try #require(
            Solution(crossword: crossword, lexicon: wordList, mustWords: ["RAT"]))

        let spans = crossword.spans
        try #require(spans.count == 2)

        // There are two valid solutions.
        // 1. spans[0] = ["RAT"], spans[1] = ["CAT", "DOG"]
        // 2. spans[0] = ["CAT", "DOG"], spans[1] = ["RAT"]
        let case1 =
            solution.domain(for: spans[0]).stringArrayRepresentation == ["RAT"]
            && solution.domain(for: spans[1]).stringArrayRepresentation == ["CAT", "DOG"]
        let case2 =
            solution.domain(for: spans[1]).stringArrayRepresentation == ["RAT"]
            && solution.domain(for: spans[0]).stringArrayRepresentation == ["CAT", "DOG"]

        #expect((case1 && !case2) || (!case1 && case2))
    }

    @Test func nodeInconsistency() throws {
        let grid = Grid(width: 4, height: 1)
        let crossword = Crossword(grid: grid)
        let wordList = ["CAT", "DOG"]

        #expect(
            Solution(crossword: crossword, lexicon: wordList) == nil,
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
        var solution = try #require(Solution(crossword: crossword, lexicon: wordList))

        #expect(solution.enforceArcConsistency(of: span1, using: span2) == true)

        // span2's domain is ["CAT", "DOG", "OWL"]. It overlaps with
        // span1 at the letter 'O'. So, the reduced domain for span1
        // should be just ["OWL"].

        #expect(solution.domain(for: span1).stringArrayRepresentation == ["OWL"])
    }
}
