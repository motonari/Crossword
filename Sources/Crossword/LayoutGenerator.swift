/// Generates layouts.
struct LayoutGenerator {
    /// Size of the crossword puzzle
    let grid: Grid

    /// The number of words in the puzzle.
    let wordCount: Int
}

/// Sequence conformance
extension LayoutGenerator: Sequence {
    func makeIterator() -> LayoutGeneratorIterator {
        return LayoutGeneratorIterator(grid: grid, wordCount: wordCount)
    }
}
