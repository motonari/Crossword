import Testing

@testable import Crossword

@Suite struct LocationIteratorTests {
    @Test("In 3x3 grid, check the iterated coordinates")
    func grid2x2() throws {
        var iterator = LocationIterator(grid: Grid(width: 3, height: 3))

        let expectations = [
            Location(x: 0, y: 0),
            Location(x: 1, y: 0),
            Location(x: 2, y: 0),
            Location(x: 0, y: 1),
            Location(x: 1, y: 1),
            Location(x: 2, y: 1),
            Location(x: 0, y: 2),
            Location(x: 1, y: 2),
            Location(x: 2, y: 2),
        ]

        for (index, expectation) in expectations.enumerated() {
            let actual = iterator.next()
            #expect(actual == expectation, "Unexpected location at index \(index).")
        }

        let optionalLocation = iterator.next()
        #expect(optionalLocation == nil)
    }
}
