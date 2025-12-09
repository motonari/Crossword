import Testing

@testable import Crossword

@Suite struct SolverTests {
    @Test func arcConsistency() throws {
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

    @Test func globalConsistency() throws {
        // :##
        // :::
        // :##
        let grid = Grid(width: 3, height: 3)
        let blackCellLayout = Layout(grid: grid, blackCells: [(1, 0), (2, 0), (1, 2), (2, 2)])
        let crossword = Crossword(grid: grid, with: blackCellLayout)
        let wordList = ["CAT", "DOG", "OWL"].map(Word.init)
        let solver = Solver(for: crossword, lexicon: wordList, mustWords: [])

        let span1 = crossword.span(at: Location(0, 1), direction: .across)!
        let span2 = crossword.span(at: Location(0, 0), direction: .down)!

        var solution = try #require(Solution(crossword: crossword, lexicon: wordList))
        solution.assign(word: Word("CAT"), to: span1)

        try #require(solver.enforceGlobalConsistency(solution: &solution))

        // span1's domain is ["CAT"]. The global consistency requires "CAT" is not in other domains.
        #expect(solution.domain(for: span1).stringArrayRepresentation == ["CAT"])
        #expect(solution.domain(for: span2).stringArrayRepresentation == ["DOG", "OWL"])
    }

    @Test func solve() throws {
        // D##
        // OWL
        // G##

        let grid = Grid(width: 3, height: 3)
        let layout = Layout(grid: grid, blackCells: [(1, 0), (2, 0), (1, 2), (2, 2)])
        let crossword = Crossword(grid: grid, with: layout)
        let wordList = ["CAT", "DOG", "OWL"].map(Word.init)
        let solver = Solver(for: crossword, lexicon: wordList)

        var solutions = [Solution]()
        try solver.solve { solution, _ in
            solutions.append(solution)
        }

        try #require(solutions.count == 1)
        let solution = try #require(solutions.first)

        #expect(
            solution.gridRepresentation == """
                D##
                OWL
                G##
                """)
    }
}
