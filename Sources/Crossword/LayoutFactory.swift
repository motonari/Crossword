import Algorithms
import Foundation

// MARK: Structure
/// Creates layouts and save them to a file.
public struct LayoutFactory {
    let grid: Grid
    let wordCount: Int
    let maxLayoutCount: Int
    public init(grid: Grid, wordCount: Int, maxLayoutCount: Int = 1_000_000) {
        self.grid = grid
        self.wordCount = wordCount
        self.maxLayoutCount = maxLayoutCount
    }
}

// MARK: Initializers
extension LayoutFactory {
}

// MARK: Build layouts
extension LayoutFactory {
    public func generate(basedOn baseLayoutFile: LayoutFile?) throws -> AsyncStream<LayoutFile> {
        if let baseLayoutFile {
            guard baseLayoutFile.grid == grid else {
                throw LayoutFileError.invalidGridSize
            }

            guard baseLayoutFile.wordCount == wordCount else {
                throw LayoutFileError.invalidWordCount
            }
        }

        return AsyncStream<LayoutFile> { continuation in
            let grid = self.grid
            let wordCount = self.wordCount
            let maxLayoutCount = self.maxLayoutCount
            var updatedLayouts = [Layout]()
            if let baseLayoutFile {
                updatedLayouts = baseLayoutFile.layouts
            }

            Task {
                let generator = LayoutGenerator(
                    grid: grid,
                    wordCount: wordCount)

                var counter = 0
                for layout in generator {
                    if Task.isCancelled {
                        break
                    }

                    let score = layout.intersectionCount(in: grid)
                    let insertingIndex = updatedLayouts.partitioningIndex {
                        score >= $0.intersectionCount(in: grid)
                    }

                    updatedLayouts.insert(layout, at: insertingIndex)
                    updatedLayouts = Array(updatedLayouts.prefix(maxLayoutCount))
                    counter += 1
                    if counter % 1000 == 0 {
                        let layoutFile = LayoutFile(
                            grid: grid,
                            wordCount: wordCount,
                            layouts: updatedLayouts)

                        continuation.yield(layoutFile)
                    }
                }

                continuation.finish()
            }
        }
    }
}
