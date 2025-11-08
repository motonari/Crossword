struct State {
    var placements = [Placement]()
    var usedWords = Set<String>()

    init(grid: Grid) {
        let north = Placement(
            word: String(repeating: "#", count: grid.width),
            start: Location(x: 0, y: 0),
            direction: .across)

        let south = Placement(
            word: String(repeating: "#", count: grid.width),
            start: Location(x: 0, y: grid.height - 1),
            direction: .across)

        let west = Placement(
            word: String(repeating: "#", count: grid.height),
            start: Location(x: 0, y: 0),
            direction: .down)

        let east = Placement(
            word: String(repeating: "#", count: grid.height),
            start: Location(x: grid.width - 1, y: 0),
            direction: .down)

        placements = [north, south, west, east]
    }

    mutating func add(_ placement: Placement) {
        placements.append(placement)
        usedWords.insert(placement.word)
    }

    func contains(_ word: String) -> Bool {
        usedWords.contains(word)
    }

    func canAccept(_ newPlacement: Placement) -> Bool {
        placements.allSatisfy { $0.compatible(with: newPlacement) }
    }

}
