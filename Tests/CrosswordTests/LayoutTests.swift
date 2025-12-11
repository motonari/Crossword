import Foundation
import Testing

@testable import Crossword

@Suite struct LayoutTests {
    @Test func initWithAllWhiteCells() throws {
        let grid = Grid(width: 4, height: 4)
        let layout = Layout(grid: grid)

        let data = layout.dataRepresentation
        #expect(data.allSatisfy { $0 == 0x00 })
    }

    @Test func dataSize() throws {
        let grid = Grid(width: 9, height: 1)
        let layout = Layout(grid: grid)

        let data = layout.dataRepresentation
        #expect(data.count == 2, "Grid of 9 x 1 requires 9 bits, which should use two bytes.")
    }

    @Test func initWithSomeBlackCells() throws {
        // BBBBWWWW
        let grid = Grid(width: 8, height: 1)
        let layout = Layout(
            grid: grid,
            blackCells: [
                (0, 0),
                (1, 0),
                (2, 0),
                (3, 0),
            ])
        let data = layout.dataRepresentation
        try #require(data.count == 1)

        #expect(data[0] == 0xF0)
    }

    @Test func outOfBoundBlackCells() async throws {
        await #expect(processExitsWith: .failure) {
            let grid = Grid(width: 1, height: 1)
            _ = Layout(
                grid: grid,
                blackCells: [
                    (1, 0)
                ])
        }
    }

    func createEmptyTemporaryFile() throws -> URL {
        let temporaryDirectoryURL = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
            .appending(component: "CrosswordTests")

        try FileManager.default.createDirectory(
            at: temporaryDirectoryURL, withIntermediateDirectories: true)

        let temporaryFileURL = temporaryDirectoryURL.appending(components: UUID().uuidString)
        FileManager.default.createFile(atPath: temporaryFileURL.path, contents: nil)

        return temporaryFileURL
    }

    @Test func initFromFile() async throws {
        // ::::
        // #:#:
        // :#:#
        // ::::
        let temporaryFileURL = try createEmptyTemporaryFile()
        defer {
            try? FileManager.default.removeItem(at: temporaryFileURL)
        }

        let data = Data([0x0A, 0x50])
        try data.write(to: temporaryFileURL)
        let grid = Grid(width: 4, height: 4)
        let fileHandle = try FileHandle(forReadingFrom: temporaryFileURL)
        let layout = try #require(try Layout(readingFrom: fileHandle, grid: grid))

        #expect(
            layout.blackCells() == [
                Location(0, 1),
                Location(2, 1),
                Location(1, 2),
                Location(3, 2),
            ])
    }
}
