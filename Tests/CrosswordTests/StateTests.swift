import Testing

@testable import Crossword

@Suite struct StateTests {
    @Test("Initial state.")
    func initialState() {
        let s = State(grid: Grid(width: 3, height: 3))
        #expect(!s.contains(""))
    }

    @Test("canAccept should return true of a new placement is compatible.")
    func canAcceptShouldReturnTrueIfCompatible() {
        var s = State(grid: Grid(width: 3, height: 3))
        let placement1 = Placement(
            word: "#A#",
            start: Location(x: 0, y: 1),
            direction: .across)
        s.add(placement1)

        let placement2 = Placement(
            word: "#A#",
            start: Location(x: 1, y: 0),
            direction: .down)

        #expect(s.canAccept(placement2))
    }

    @Test("canAccept should return false of a new placement is not compatible.")
    func canAcceptShouldReturnFalseIfNotCompatible() {
        var s = State(grid: Grid(width: 3, height: 3))
        let placement1 = Placement(
            word: "#A#",
            start: Location(x: 0, y: 1),
            direction: .across)
        s.add(placement1)

        let placement2 = Placement(
            word: "#B#",
            start: Location(x: 1, y: 0),
            direction: .down)

        #expect(!s.canAccept(placement2))
    }
}
