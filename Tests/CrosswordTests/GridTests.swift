import Testing

@testable import Crossword

@Suite struct GridTests {
    @Test func creation() {
        let grid = Grid(width: 2, height: 1)
        #expect(grid.width == 2)
        #expect(grid.height == 1)
    }

    @Test func negativeSize() async {
        await #expect(processExitsWith: .failure) {
            _ = Grid(width: -1, height: 0)
        }
    }

    @Test func emptyGrid() async {
        await #expect(processExitsWith: .failure) {
            _ = Grid(width: 0, height: 1)
        }
    }
}
