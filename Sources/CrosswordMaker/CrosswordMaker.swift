import ArgumentParser
import Crossword
import Foundation

@main
struct CrosswordMaker: AsyncParsableCommand {
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

    @Option(name: .long, help: "The layout data file.")
    var layoutFileName: String?

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
    ) async throws {
        let defaultLayoutFileURL = LayoutFile.defaultLayoutFileURL(
            grid: grid, wordCount: wordCount)

        let layoutStore = try await LayoutFile(contentsOf: defaultLayoutFileURL)
        var progressCount = 0
        var intersectionCount = 0
        for blackCellLayout in layoutStore.layouts {
            progressCount += 1
            intersectionCount += blackCellLayout.score.0
            if progressCount % 1000 == 0 {
                print("\(progressCount) / \(layoutStore.layouts.count)")
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

    func makeLayoutFile(
        grid: Grid,
        wordCount: Int,
        maxLayoutCount: Int,
        layoutFileURL: URL?
    ) async throws {
        let layoutFileURL =
            layoutFileURL ?? LayoutFile.defaultLayoutFileURL(grid: grid, wordCount: wordCount)

        let factory = LayoutFactory(
            grid: grid,
            wordCount: wordCount,
            maxLayoutCount: maxLayoutCount)

        let layoutFile = try? await LayoutFile(contentsOf: layoutFileURL)
        for await layoutFile in try factory.generate(basedOn: layoutFile) {
            print(
                "score: \(layoutFile.maxIntersectionCount) number of layouts: \(layoutFile.layouts.count)"
            )

            try await layoutFile.write(to: layoutFileURL)
        }

        print("Layout file was created at: \(layoutFileURL.path)")
        return

    }

    mutating func run() async throws {
        let grid = Grid(width: width, height: height)

        if generateLayoutFile {
            var layoutFileURL: URL? = nil
            if let layoutFileName {
                layoutFileURL = URL(fileURLWithPath: layoutFileName)
            }
            try await makeLayoutFile(
                grid: grid, wordCount: count, maxLayoutCount: maxLayoutCount,
                layoutFileURL: layoutFileURL)
        } else {

            let lexicon = Lexicon().words
            print("Solving with word count = \(count), mandatory words: \(mandatoryWords)")
            try await makeCrossword(
                grid: grid,
                wordCount: count,
                lexicon: lexicon,
                mustWords: mandatoryWords)
        }
    }
}
