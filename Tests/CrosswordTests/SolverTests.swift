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
        let wordList = ["CAT", "DOG", "OWL"].map(Word.init)
        let solver = Solver(for: crossword, lexicon: wordList, mustWords: [])

        var solution = try #require(Solution(crossword: crossword, lexicon: wordList))
        try #require(solver.enforceArcConsistency(solution: &solution))

        let span1 = crossword.span(at: Location(0, 1), direction: .across)!
        let span2 = crossword.span(at: Location(0, 0), direction: .down)!

        // span2's domain is ["CAT", "DOG", "OWL"]. It overlaps with
        // span1 at the letter 'O'. So, the reduced domain for span1
        // should be just ["OWL"].
        //
        // Since span1's domain is now just ["OWL"], span2's value
        // must be "DOG".

        #expect(solution.domain(for: span1).stringArrayRepresentation == ["OWL"])
        #expect(solution.domain(for: span2).stringArrayRepresentation == ["DOG"])
    }

    @Test func solve() throws {
        // D##
        // OWL
        // G##

        let grid = Grid(width: 3, height: 3)
        let layout = Layout(grid: grid, blackCells: [(1, 0), (2, 0), (1, 2), (2, 2)])
        let crossword = Crossword(grid: grid, with: layout)
        let wordList = ["CAT", "DOG", "OWL"].map(Word.init)
        var solver = Solver(for: crossword, lexicon: wordList)

        let solutions = solver.solve()

        try #require(solutions.count == 1)
        let solution = try #require(solutions.first)

        #expect(
            solution.stringRepresentation == """
                D##
                OWL
                G##
                """)
    }
}
