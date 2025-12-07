import ArgumentParser
import Crossword
import Foundation

@main
struct CrosswordMaker: ParsableCommand {
    @Flag(name: .short, help: "Generate layout file.")
    var generateLayoutFile = false

    @Option(name: .customLong("max-layout-count"))
    var maxLayoutCount: Int = 10_000_000

    @Option(
        name: [.customShort("m"), .customLong("mandatory-words")],
        help: "List of words the puzzle must have.",
        transform: { Word($0.uppercased()) }
    )
    var mandatoryWords = [Word]()

    @Option(name: .shortAndLong, help: "The output file.")
    var outputFileName = "output.html"

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

            var solutionWasFound = false
            try solver.solve { (solution, stop) in
                let renderer = HTMLSolutionRenderer(to: URL(fileURLWithPath: outputFileName))
                try renderer.render(solution: solution)
                stop = true
                solutionWasFound = true
            }

            if solutionWasFound {
                break
            }
        }
    }

    mutating func run() throws {
        let grid = Grid(width: width, height: height)

        if generateLayoutFile {
            let fileURL = try LayoutStore.generateLayoutFile(
                grid: grid, wordCount: count, maxLayoutCount: maxLayoutCount)
            print("Layout file was created at: \(fileURL.path)")
            return
        }

        let lexicon = Lexicon().words
        print("Solving with word count = \(count), mandatory words: \(mandatoryWords)")
        try makeCrossword(
            grid: grid,
            wordCount: count,
            lexicon: lexicon,
            mustWords: mandatoryWords)
    }
}
