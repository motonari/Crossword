import Foundation

public struct LayoutScore: Sequence {
    let fileURL: URL
    let grid: Grid
    let wordCount: Int

    public struct Iterator: IteratorProtocol {
        public typealias Element = Layout

        let fileHandle: FileHandle
        let grid: Grid

        init(layoutFileURL: URL, grid: Grid) throws {
            self.fileHandle = try FileHandle(forReadingFrom: layoutFileURL)
            self.grid = grid
        }

        public mutating func next() -> Layout? {
            do {
                return try Layout(fileHandle: fileHandle, grid: grid)
            } catch {
                return nil
            }
        }

    }

    public init(grid: Grid, wordCount: Int) throws {
        self.grid = grid
        self.wordCount = wordCount
        self.fileURL = Self.defaultLayoutFileURL(grid: grid, wordCount: wordCount)

        // preflight check
        _ = try Iterator(layoutFileURL: fileURL, grid: grid)
    }

    public var count: Int {
        let attributes = try! FileManager.default.attributesOfItem(atPath: fileURL.path)
        let fileSize = attributes[FileAttributeKey.size] as! UInt64
        return Int(fileSize / UInt64(Layout.storageSize(for: grid)))
    }

    private static func defaultLayoutFileURL(grid: Grid, wordCount: Int) -> URL {
        let directoryURL = URL(
            fileURLWithPath: FileManager.default.currentDirectoryPath, isDirectory: true)
        let fileName = "crossword_layout_\(grid.width)x\(grid.height)_\(wordCount).data"
        let fileURL = directoryURL.appendingPathComponent(fileName, isDirectory: false)
        return fileURL
    }

    public static func generateLayoutFile(
        grid: Grid, wordCount: Int, maxLayoutCount: Int = 1_000_000
    ) throws -> URL {
        let fileURL = defaultLayoutFileURL(grid: grid, wordCount: wordCount)
        FileManager.default.createFile(atPath: fileURL.path, contents: nil)

        var layouts = [Layout]()
        for layout in LayoutGenerator(grid: grid, wordCount: wordCount) {
            if layouts.count > maxLayoutCount {
                break
            }

            if layouts.count % 1000 == 0 {
                print("\(layouts.count) / \(maxLayoutCount)")
            }
            layouts.append(layout)
        }

        // Sort by intersection count
        layouts.sort { $0.intersectionCount(in: grid) > $1.intersectionCount(in: grid) }

        let fileHandle = try FileHandle(forWritingTo: fileURL)
        for layout in layouts {
            fileHandle.write(layout.dataRepresentation)
        }
        try fileHandle.close()

        return fileURL
    }

    public func makeIterator() -> Iterator {
        let fileURL = Self.defaultLayoutFileURL(grid: grid, wordCount: wordCount)
        return try! Iterator(layoutFileURL: fileURL, grid: grid)
    }

}
