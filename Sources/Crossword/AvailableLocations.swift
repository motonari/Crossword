struct AvailableLocations: Sequence {
    let grid: Grid
    func makeIterator() -> LocationIterator {
        return LocationIterator(grid: grid)
    }
}
