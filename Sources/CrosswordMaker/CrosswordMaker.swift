import ArgumentParser
import Crossword
import Foundation

@main
struct CrosswordMaker: ParsableCommand {
    @Flag(name: .short, help: "Generate layout file.")
    var generateLayoutFile = false

    @Option(name: .shortAndLong, help: "A word to include in the puzzle.")
    var mustWord: String?

    @Option(name: .shortAndLong, help: "The output file.")
    var outputFileName: String

    @Option(name: .shortAndLong, help: "How many words in the puzzle?")
    var count = 12

    @Option(name: .long, help: "Width of the puzzle.")
    var width = 12

    @Option(name: .long, help: "Height of the puzzle.")
    var height = 12

    func makeCrossword(
        grid: Grid,
        wordCount: Int,
        lexicon: [Word],
        mustWords: [Word]
    ) throws {
        let layoutStore = try LayoutStore(grid: grid, wordCount: wordCount)
        var progressCount = 0
        var intersectionCount = 0
        for blackCellLayout in layoutStore {
            progressCount += 1
            intersectionCount += blackCellLayout.intersectionCount(in: grid)
            if progressCount % 1000 == 0 {
                print("\(progressCount) / \(layoutStore.count)")
                print("Score = \(intersectionCount / 1000)")
                intersectionCount = 0
            }

            let grid = Grid(width: width, height: height)
            let crossword = Crossword(grid: grid, with: blackCellLayout)

            let solver = Solver(for: crossword, lexicon: lexicon, mustWords: mustWords)

            let solutions = solver.solve()
            if !solutions.isEmpty {
                let renderer = HTMLSolutionRenderer(to: URL(fileURLWithPath: outputFileName))
                try renderer.render(solution: solutions[0])
                break
            }
        }
    }

    func makeCrosswordTest(
        grid: Grid,
        wordCount: Int,
        lexicon: [Word],
        mustWords: [Word]
    ) {
        let layout = Layout(
            grid: grid,
            blackCells: [
                (4, 0),
                (5, 0),

                (1, 1),
                (3, 1),
                (5, 1),
                (7, 1),
                (8, 1),
                (10, 1),

                (1, 2),
                (7, 2),

                (0, 3),
                (1, 3),
                (2, 3),
                (3, 3),
                (5, 3),
                (6, 3),
                (7, 3),
                (8, 3),
                (10, 3),

                (0, 4),
                (1, 4),
                (3, 4),
                (5, 4),
                (7, 4),

                (0, 5),
                (7, 5),
                (8, 5),
                (10, 5),

                (1, 6),
                (3, 6),
                (5, 6),
                (7, 6),
                (11, 6),

                (8, 7),
                (9, 7),
                (10, 7),
                (11, 7),

                (1, 8),
                (3, 8),
                (5, 8),
                (7, 8),
                (8, 8),
                (10, 8),

                (0, 9),
                (10, 9),

                (0, 10),
                (1, 10),
                (3, 10),
                (5, 10),
                (6, 10),
                (7, 10),
                (8, 10),
                (10, 10),

                (8, 11),
            ])

        let grid = Grid(width: width, height: height)
        let crossword = Crossword(grid: grid, with: layout)

        let solver = Solver(for: crossword, lexicon: lexicon, mustWords: mustWords)

        let solutions = solver.solve()
    }

    mutating func run() throws {
        let grid = Grid(width: width, height: height)

        if generateLayoutFile {
            let fileURL = try LayoutStore.generateLayoutFile(grid: grid, wordCount: count)
            print("Layout file was created at: \(fileURL.path)")
            return
        }

        let lexicon = Lexicon().words
        let mustWords: [Word] =
            if let mustWord {
                [Word(mustWord.uppercased())]
            } else {
                []
            }

        print("Solving with word count = \(count), mustWord: \(mustWords)")
        try makeCrossword(
            grid: grid,
            wordCount: count,
            lexicon: lexicon,
            mustWords: mustWords)
    }
}
