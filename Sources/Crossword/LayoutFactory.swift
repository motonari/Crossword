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

        return AsyncStream<LayoutFile>(bufferingPolicy: .bufferingOldest(2)) { continuation in
            let grid = self.grid
            let wordCount = self.wordCount
            let maxLayoutCount = self.maxLayoutCount
            var updatedLayoutData = LayoutData(grid: grid)
            if let baseLayoutFile {
                updatedLayoutData = baseLayoutFile.layoutData
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
                    updatedLayoutData.insert(layout, maxLayoutCount: maxLayoutCount)

                    counter += 1
                    if counter % 1000 == 0 {
                        let layoutFile = LayoutFile(
                            grid: grid,
                            wordCount: wordCount,
                            layoutData: updatedLayoutData)

                        var result = continuation.yield(layoutFile)
                        while case .dropped(let failedItem) = result {
                            try await Task.sleep(for: .milliseconds(100))
                            result = continuation.yield(consume failedItem)
                        }
                    }
                }

                continuation.finish()
            }
        }
    }
}
