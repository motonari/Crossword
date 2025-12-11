import Foundation

// MARK: Structure
/// Represents a layout file.
///
/// A layout file has the following structure. Integers are stored
/// in the little endian.
///
/// ```
/// Offset | Size | Contents
/// --------------------------------
///      0 |    4 | magic: `CWL0`
///      4 |    2 | grid width
///      6 |    2 | grid height
///      8 |    4 | word count
///     12 |    n | layouts
/// ```
///
/// A layout is a bit field of the grid (raster scan order), where
/// white cell is 0 and black cell is 1. Each layout starts at the
/// next byte boundary.
public struct LayoutFile: Sendable {
    public let grid: Grid
    public let wordCount: Int

    let layoutData: LayoutData
}

// MARK: Initializers
extension LayoutFile {
    public init(contentsOf layoutFileURL: URL) async throws {
        let layoutFile = try await LayoutFile.read(from: layoutFileURL)
        self = layoutFile
    }
}

// MARK: Layout Sequence
extension LayoutFile {
    public var layouts: some Collection<Layout> {
        layoutData
    }
}

// MARK: State
extension LayoutFile {
    public var maxIntersectionCount: Int {
        guard let layout = layoutData.first else {
            return 0
        }
        return layout.score.0
    }
}

// MARK: File I/O
extension LayoutFile {
    public func write(to layoutFileURL: URL) async throws {

        try await withCheckedThrowingContinuation { continuation in
            do {
                let temporaryDirectoryURL = try FileManager.default.url(
                    for: .itemReplacementDirectory,
                    in: .userDomainMask,
                    appropriateFor: layoutFileURL,
                    create: true)

                let temporaryLayoutFileURL = temporaryDirectoryURL.appending(
                    component: layoutFileURL.lastPathComponent, directoryHint: .notDirectory)

                _ = FileManager.default.createFile(
                    atPath: temporaryLayoutFileURL.path, contents: nil)

                let fileHandle = try FileHandle(forWritingTo: temporaryLayoutFileURL)
                defer {
                    try? fileHandle.close()
                }

                try fileHandle.truncate(atOffset: 0)
                try fileHandle.write(contentsOf: Data("CWL0".utf8))
                try fileHandle.write(
                    contentsOf: withUnsafeBytes(of: UInt16(grid.width).littleEndian) { Data($0) })
                try fileHandle.write(
                    contentsOf: withUnsafeBytes(of: UInt16(grid.height).littleEndian) { Data($0) })
                try fileHandle.write(
                    contentsOf: withUnsafeBytes(of: UInt32(wordCount).littleEndian) { Data($0) })

                try fileHandle.write(contentsOf: layoutData.dataRepresentation)

                try fileHandle.close()
                _ = try FileManager.default.replaceItemAt(
                    layoutFileURL, withItemAt: temporaryLayoutFileURL)

                continuation.resume(returning: ())
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }

    private static func read(from layoutFileURL: URL) async throws -> LayoutFile {
        let fileHandle = try FileHandle(forReadingFrom: layoutFileURL)
        defer { try? fileHandle.close() }

        return try await withCheckedThrowingContinuation { continuation in
            do {
                let magicData = try fileHandle.read(count: 4)
                guard
                    magicData.count == 4,
                    String(data: magicData, encoding: .utf8) == "CWL0"
                else {
                    throw LayoutFileError.invalidMagicCode
                }

                let width = Int(try fileHandle.load(as: UInt16.self))
                let height = Int(try fileHandle.load(as: UInt16.self))
                let wordCount = Int(try fileHandle.load(as: UInt32.self))

                let grid = Grid(width: width, height: height)
                let layoutData = try LayoutData(readingFrom: fileHandle, grid: grid)
                let layoutFile = LayoutFile(
                    grid: grid,
                    wordCount: wordCount,
                    layoutData: layoutData)
                continuation.resume(returning: layoutFile)
            } catch {
                continuation.resume(throwing: error)
            }
        }

    }
}

// MARK: Utility
extension LayoutFile {
    public static func defaultLayoutFileURL(grid: Grid, wordCount: Int) -> URL {
        let directoryURL = URL(
            fileURLWithPath: FileManager.default.currentDirectoryPath, isDirectory: true)
        let fileName = "crossword_layout_\(grid.width)x\(grid.height)_\(wordCount).data"
        let fileURL = directoryURL.appendingPathComponent(fileName, isDirectory: false)
        return fileURL
    }
}

// MARK: LayoutFileError error
/// Creates layouts and save them to a file.
public enum LayoutFileError: Error {
    case invalidMagicCode
    case invalidFileLength
    case invalidGridSize
    case invalidWordCount
}

// MARK: FileHandle extension
extension FileHandle {
    func read(count: Int) throws -> Data {
        guard
            let data = try self.read(upToCount: count),
            data.count == count
        else {
            throw LayoutFileError.invalidFileLength
        }
        return data
    }

    func load<T>(as type: T.Type) throws -> T where T: FixedWidthInteger {
        let data = try read(count: MemoryLayout<T>.size)
        return data.withUnsafeBytes { $0.load(as: type) }.littleEndian
    }
}
