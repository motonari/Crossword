import Testing

@testable import Crossword

@Suite struct PlacementTests {

    @Test("Initialization")
    func initialization() {
        let word = "01234"
        let placement = Placement(
            word: word,
            start: Location(0, 0),
            direction: .across)

        #expect(placement.word == word)
        #expect(placement.start == Location(0, 0))
        #expect(placement.direction == .across)
    }

    @Test("One across letter at top-left should contains (0, 0) and (1, 0)")
    func oneLetterContainsTheLocation() {
        let word = "A"
        let placement = Placement(
            word: word,
            start: Location(0, 0),
            direction: .across)

        #expect(
            placement.contains(Location(0, 0)),
            "The placement should occupy (0, 0).")
        #expect(
            placement.contains(Location(1, 0)),
            "The placement should occupy (1, 0).")

        #expect(
            !placement.contains(Location(2, 0)),
            "The placement should NOT occupy (2, 0).")
        #expect(
            !placement.contains(Location(0, 1)),
            "The placement should NOT occupy (0, 1).")
    }

    @Test("Two non-overlapping placements should be compatible.")
    func nonOverlappingPlacements() {
        let placementA = Placement(
            word: "#A#",
            start: Location(0, 0),
            direction: .across)

        let placementB = Placement(
            word: "#B#",
            start: Location(0, 1),
            direction: .across)

        #expect(placementA.compatible(with: placementB))
        #expect(placementB.compatible(with: placementA))
    }

    @Test("Two overlapping placements of a same direction should be incompatible.")
    func overlappingPlacementsOfSameDirection() {
        let placementA = Placement(
            word: "#A#",
            start: Location(0, 0),
            direction: .across)

        let placementB = Placement(
            word: "#A#",
            start: Location(0, 0),
            direction: .across)

        #expect(!placementA.compatible(with: placementB))
        #expect(!placementB.compatible(with: placementA))
    }

    @Test("Two overlapping placements of a matching letter.")
    func overlappingPlacementsWithMatchingLetter() {
        //  012
        // 0 #
        // 1#A#
        // 2 #

        let placementA = Placement(
            word: "#A#",
            start: Location(0, 1),
            direction: .across)

        let placementB = Placement(
            word: "#A#",
            start: Location(1, 0),
            direction: .down)

        #expect(placementA.compatible(with: placementB))
        #expect(placementB.compatible(with: placementA))
    }

    @Test("Crossing point is in a middle of the words.")
    func overlappingPlacementsWithMatchingLetter2() {
        //  0123456
        // 0     #
        // 1     P
        // 2     O
        // 3 #APPLE#
        // 4     E
        // 5     #

        let placementA = Placement(
            word: "#APPLE#",
            start: Location(1, 3),
            direction: .across)

        let placementB = Placement(
            word: "#POLE#",
            start: Location(5, 0),
            direction: .down)

        #expect(placementA.compatible(with: placementB))
        #expect(placementB.compatible(with: placementA))
    }

    @Test("Crossing point is at the filler.")
    func overlappingPlacementsWithCrossPointAtFiller() {
        //  01234567
        // 0       #
        // 1       H
        // 2       I
        // 3 #APPLE#

        let placementA = Placement(
            word: "#APPLE#",
            start: Location(1, 3),
            direction: .across)

        let placementB = Placement(
            word: "#HI#",
            start: Location(7, 0),
            direction: .down)

        #expect(placementA.compatible(with: placementB))
        #expect(placementB.compatible(with: placementA))
    }

    @Test("Two overlapping placements without a matching letter.")
    func overlappingPlacementsWithoutMatchingLetter() {
        let placementA = Placement(
            word: "#A#",
            start: Location(0, 1),
            direction: .across)

        let placementB = Placement(
            word: "#B#",
            start: Location(1, 0),
            direction: .down)

        #expect(!placementA.compatible(with: placementB))
        #expect(!placementB.compatible(with: placementA))
    }
}
