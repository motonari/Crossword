import Testing

@testable import Crossword

@Suite("Location tests") struct LocationTests {

    @Test func creation() {
        let loc = Location(x: 2, y: 3)
        #expect(loc.x == 2)
        #expect(loc.y == 3)
    }

}
