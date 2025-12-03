import Testing

@testable import Crossword

@Suite struct LocationIteratorTests {
    @Test("In 3x3 grid, check the iterated coordinates")
    func grid2x2() throws {
        var iterator = LocationIterator(grid: Grid(width: 3, height: 3))

        let expectations = [
            Location(0, 0),
            Location(1, 0),
            Location(2, 0),
            Location(0, 1),
            Location(1, 1),
            Location(2, 1),
            Location(0, 2),
            Location(1, 2),
            Location(2, 2),
        ]

        for (index, expectation) in expectations.enumerated() {
            let actual = iterator.next()
            #expect(actual == expectation, "Unexpected location at index \(index).")
        }

        let optionalLocation = iterator.next()
        #expect(optionalLocation == nil)
    }
}
