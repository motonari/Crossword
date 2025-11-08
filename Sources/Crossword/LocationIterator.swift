struct LocationIterator: IteratorProtocol {
    let grid: Grid
    var location: Location?

    init(grid: Grid) {
        let initialLocation = Location(x: 0, y: 0)
        if initialLocation.x < grid.width && initialLocation.y < grid.height {
            self.location = initialLocation
        } else {
            self.location = nil
        }
        self.grid = grid
    }

    mutating func next() -> Location? {
        guard let currentLocation = location else {
            return nil
        }

        var x = currentLocation.x
        var y = currentLocation.y

        x = (x + 1) % grid.width
        if x == 0 {
            y = (y + 1) % grid.height
        }

        if x == 0 && y == 0 {
            location = nil
        } else {
            location = Location(x: x, y: y)
        }
        return currentLocation
    }
}
