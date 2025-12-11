import Foundation
import Testing

@testable import Crossword

@Suite struct LayoutDataTests {
    @Test func duplication() throws {
        let grid = Grid(width: 2, height: 2)
        let layout1 = Layout(grid: grid)
        let layout2 = Layout(grid: grid)

        var layoutData = LayoutData(grid: grid)
        layoutData.insert(layout1, maxLayoutCount: 2)
        layoutData.insert(layout2, maxLayoutCount: 2)

        #expect(layoutData.count == 1, "LayoutData has only unique layouts.")
    }

    @Test func sort() throws {
        let grid = Grid(width: 2, height: 2)
        let layout1 = Layout(grid: grid, blackCells: [(0, 0)])
        let layout2 = Layout(grid: grid)

        try #require(layout1 < layout2, "layout1 has a black cell, so it should have lower score.")

        var layoutData = LayoutData(grid: grid)
        layoutData.insert(layout1, maxLayoutCount: 2)
        layoutData.insert(layout2, maxLayoutCount: 2)

        try #require(layoutData.count == 2)

        #expect(Layout(grid: grid, data: layoutData[0]) == layout2)
        #expect(Layout(grid: grid, data: layoutData[1]) == layout1)
    }

    @Test func truncation() throws {
        let grid = Grid(width: 2, height: 2)
        let layout1 = Layout(grid: grid, blackCells: [(0, 0), (1, 0)])
        let layout2 = Layout(grid: grid, blackCells: [(0, 0)])
        let layout3 = Layout(grid: grid)

        var layoutData = LayoutData(grid: grid)
        layoutData.insert(layout1, maxLayoutCount: 2)
        layoutData.insert(layout2, maxLayoutCount: 2)
        layoutData.insert(layout3, maxLayoutCount: 2)

        try #require(layoutData.count == 2)

        #expect(Layout(grid: grid, data: layoutData[0]) == layout3)
        #expect(Layout(grid: grid, data: layoutData[1]) == layout2)
    }
}
