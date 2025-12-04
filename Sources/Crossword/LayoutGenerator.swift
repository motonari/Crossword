/// Generates layouts.
struct LayoutGenerator {
    /// Size of the crossword puzzle
    let grid: Grid

    /// The number of words in the puzzle.
    let wordCount: Int

    /// The minimum word length
    let minWordLength = 3

    /// Width of beam search
    let beamWidth: Int = 4
}

/// Sequence conformance
extension LayoutGenerator: Sequence {
    func makeIterator() -> LayoutGeneratorIterator {
        return LayoutGeneratorIterator(
            grid: grid,
            wordCount: wordCount,
            minWordLength: minWordLength,
            beamWidth: beamWidth)
    }
}
