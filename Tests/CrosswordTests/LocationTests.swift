import Testing

@testable import Crossword

@Suite("Location tests") struct LocationTests {

    @Test func creation() {
        let loc = Location(2, 3)
        #expect(loc.x == 2)
        #expect(loc.y == 3)
    }

    @Test func plus() {
        let loc1 = Location(2, 3)
        let loc2 = loc1 + (2, 1)
        #expect(loc2 == Location(4, 4))
    }

    @Test func minus() {
        let loc1 = Location(2, 3)
        let loc2 = loc1 - (2, 1)
        #expect(loc2 == Location(0, 2))
    }

    @Test func additionCompoundAssignment() {
        var loc = Location(2, 3)
        loc += (2, 1)
        #expect(loc == Location(4, 4))
    }

    @Test func subtractCompoundAssignment() {
        var loc = Location(2, 3)
        loc -= (2, 1)
        #expect(loc == Location(0, 2))
    }
}
