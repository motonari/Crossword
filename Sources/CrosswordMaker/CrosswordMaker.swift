import ArgumentParser
import Crossword
import Darwin

@main
struct CrosswordMaker: ParsableCommand {
    @Flag(name: .short, help: "Generate layout file.")
    var generateLayoutFile = false

    @Option(name: .shortAndLong, help: "A word to include in the puzzle.")
    var mustWord: String?

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
                fputs("\(progressCount) / \(layoutStore.count)\n", stderr)
                fputs("Score = \(intersectionCount / 1000)\n", stderr)
                intersectionCount = 0
            }

            let grid = Grid(width: width, height: height)
            let crossword = Crossword(grid: grid, with: blackCellLayout)

            let solver = Solver(for: crossword, lexicon: lexicon, mustWords: mustWords)

            let solutions = solver.solve()
            if !solutions.isEmpty {
                print(solutions[0])
                break
            }
        }
    }

    mutating func run() throws {
        let grid = Grid(width: width, height: height)

        if generateLayoutFile {
            let fileURL = try LayoutStore.generateLayoutFile(grid: grid, wordCount: count)
            print("Layout file was created at: \(fileURL.path)")
            return
        }

        let lexicon = Lexicon.full
        let mustWords: [Word] =
            if let mustWord {
                [Word(mustWord.uppercased())]
            } else {
                []
            }

        fputs("Solving with word count = \(count), mustWord: \(mustWords)\n", stderr)
        try makeCrossword(
            grid: grid,
            wordCount: count,
            lexicon: lexicon,
            mustWords: mustWords)
    }
}
