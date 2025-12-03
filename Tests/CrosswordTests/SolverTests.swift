import Testing

@testable import Crossword

@Suite struct SolverTests {
    @Test func ac3() throws {
        // :##
        // :::
        // :##
        let grid = Grid(width: 3, height: 3)
        let blackCellLayout = Layout(grid: grid, blackCells: [(1, 0), (2, 0), (1, 2), (2, 2)])
        let crossword = Crossword(grid: grid, with: blackCellLayout)
        let wordList = ["CAT", "DOG", "OWL"]
        let solver = Solver(for: crossword, lexicon: wordList, mustWords: [])

        var domains = try #require(DomainMap(crossword: crossword, lexicon: wordList))
        try #require(solver.enforceArcConsistency(domains: &domains))

        let span1 = crossword.span(at: Location(0, 1), direction: .across)!
        let span2 = crossword.span(at: Location(0, 0), direction: .down)!

        // span2's domain is ["CAT", "DOG", "OWL"]. It overlaps with
        // span1 at the letter 'O'. So, the reduced domain for span1
        // should be just ["OWL"].
        //
        // Since span1's domain is now just ["OWL"], span2's value
        // must be "DOG".

        #expect(domains.values(for: span1) == ["OWL"])
        #expect(domains.values(for: span2) == ["DOG"])
    }

    @Test func solve() throws {
        // D##
        // OWL
        // G##

        let grid = Grid(width: 3, height: 3)
        let layout = Layout(grid: grid, blackCells: [(1, 0), (2, 0), (1, 2), (2, 2)])
        let crossword = Crossword(grid: grid, with: layout)
        let wordList = ["CAT", "DOG", "OWL"]
        let solver = Solver(for: crossword, lexicon: wordList)

        let solutions = solver.solve()

        try #require(solutions.count == 1)
        let solution = try #require(solutions.first)
        #expect(
            solution == """
                D##
                OWL
                G##
                """)
    }
}
