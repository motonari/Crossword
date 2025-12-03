struct Locations: Sequence {
    let grid: Grid
    func makeIterator() -> LocationIterator {
        return LocationIterator(grid: grid)
    }
}
