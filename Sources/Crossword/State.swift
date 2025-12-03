public struct State: Hashable, Equatable {
    var placements = Set<Placement>()
    var usedWords = Set<String>()
    let grid: Grid

    public init(grid: Grid) {
        let north = Placement(
            word: String(repeating: "#", count: grid.width),
            start: Location(0, 0),
            direction: .across)

        let south = Placement(
            word: String(repeating: "#", count: grid.width),
            start: Location(0, grid.height - 1),
            direction: .across)

        let west = Placement(
            word: String(repeating: "#", count: grid.height),
            start: Location(0, 0),
            direction: .down)

        let east = Placement(
            word: String(repeating: "#", count: grid.height),
            start: Location(grid.width - 1, 0),
            direction: .down)

        self.placements = Set([north, south, west, east])
        self.grid = grid
    }

    public var value: Double {
        var overlapCount = 0.0
        for placementA in placements {
            for placementB in placements {
                if placementA.crossing(with: placementB) {
                    overlapCount += 1.0
                }
            }
        }
        return overlapCount
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(placements)
    }

    public static func == (lhs: State, rhs: State) -> Bool {
        return lhs.placements == rhs.placements
    }

    public func adding(_ placement: Placement) -> State {
        var newState = self
        newState.placements.insert(placement)
        newState.usedWords.insert(placement.word)
        return newState
    }

    func contains(_ word: String) -> Bool {
        usedWords.contains(word)
    }

    func canAccept(_ newPlacement: Placement) -> Bool {
        guard
            placements.allSatisfy(
                { $0.compatible(with: newPlacement) })
        else { return false }

        return true

    }

    public func dump() {
        let charGridRow = [Character](repeating: " ", count: grid.width)
        var charGrid = [[Character]](repeating: charGridRow, count: grid.height)
        for placement in placements {
            let stepX = placement.direction == .across ? 1 : 0
            let stepY = placement.direction == .down ? 1 : 0
            var x = placement.start.x
            var y = placement.start.y

            for char in placement.word {
                charGrid[y][x] = char
                x += stepX
                y += stepY
            }
        }

        for row in charGrid {
            var rowString = ""
            for char in row {
                rowString.append(char)
            }
            print(rowString)
        }
    }
}
