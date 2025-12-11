import Foundation
import Synchronization

/// Locations of black cells in the grid.
public struct Layout: Sendable {

    private let grid: Grid
    private var storage: [UInt8]
    private let scoreCache = ScoreCacheWrapper()
}


// MARK: Initializers.
extension Layout {
    /// Creates a layout with all white cells.
    init(grid: Grid) {
        let storageSize = Self.storageSize(for: grid)
        self.grid = grid
        self.storage = [UInt8](repeating: 0, count: storageSize)
    }

    /// Creates a layout with specified black cells.
    ///
    /// - Parameters:
    ///  - grid: The size of the crossword.
    ///  - blackCells: List of black cell locations.
    init(grid: Grid, blackCells: [Location]) {
        self.init(grid: grid)

        for location in blackCells {
            guard grid.contains(location) else {
                fatalError(
                    "Specified black cell location (\(location)) is "
                        + "out of bound of the grid (\(grid.width) x \(grid.height))."
                )
            }

            let (byteOffset, bitOffset) = offset(at: location, in: grid)
            guard byteOffset < storage.count else {
                fatalError("Out of bound location: \(location)")
            }
            storage[byteOffset] |= (0x01 << bitOffset)
        }
    }

    /// Creates a layout with specified black cells.
    ///
    /// - Parameters:
    ///  - grid: The size of the crossword.
    ///  - blackCells: List of black cell locations.
    init(grid: Grid, blackCells: [(Int, Int)]) {
        self.init(grid: grid, blackCells: blackCells.map(Location.init))
    }

    /// Creates a layout by reading byte stream from an open file
    /// handle.
    ///
    /// - Parameters:
    ///  - fileHandle: The file handle from which the object will be created.
    ///  - grid: The size of the crossword.
    init?(readingFrom fileHandle: FileHandle, grid: Grid) throws {
        let bytesPerLayout = Self.storageSize(for: grid)
        guard
            let storage = try fileHandle.read(upToCount: bytesPerLayout),
            storage.count == bytesPerLayout
        else {
            return nil
        }
        self.grid = grid
        self.storage = Array(storage)
    }

    init(grid: Grid, data: Data) {
        self.grid = grid
        self.storage = Array(data)
    }
}

// MARK: Comparable.
extension Layout: Comparable {

    /// Compare two layouts.
    ///
    /// A layout is "greater" than another if it has
    ///  1. More intersections.
    ///  2. More white cells.
    ///  3. Compare bits field numerically.
    ///
    public static func < (lhs: Layout, rhs: Layout) -> Bool {
        guard lhs.grid == rhs.grid else {
            fatalError("No comparison is possible between layouts of different grid size.")
        }

        let (intersectionCount1, whiteCellCount1) = lhs.score
        let (intersectionCount2, whiteCellCount2) = rhs.score

        if intersectionCount1 != intersectionCount2 {
            return intersectionCount1 < intersectionCount2
        }

        if whiteCellCount1 != whiteCellCount2 {
            return whiteCellCount1 < whiteCellCount2
        }

        return lhs.storage.lexicographicallyPrecedes(rhs.storage)
    }
}

// MARK: Hashable.
extension Layout: Hashable {
    public static func == (lhs: Layout, rhs: Layout) -> Bool {
        return lhs.storage == rhs.storage
    }

    public func hash(into hasher: inout Hasher) {
        storage.hash(into: &hasher)
    }
}

/// Cell accessors
extension Layout {
    enum Color {
        case white
        case black
    }

    /// Returns cell's color
    /// - Parameters:
    ///   - location: Cell's coordinates.
    func cell(at location: Location) -> Color {
        guard grid.contains(location) else {
            fatalError(
                """
                Location (\(location.x), \(location.y)) is
                out of bound of the grid \(grid.width) x \(grid.height).
                """
            )
        }

        let index = location.y * grid.width + location.x
        let (byteOffset, bitOffset) = offset(for: index)

        guard byteOffset < storage.count else {
            fatalError("Out of bound index: \(index)")
        }

        let bits = storage[byteOffset]
        return (bits & (0x01 << bitOffset)) == 0 ? .white : .black

    }

    /// Returns a tuple `(byteOffset, bitOffset)` for the specified raster index.
    /// - Parameters:
    ///  - index: The raster index of the cell's coordinates, which is `y * width + x`.
    /// - Returns: A tuple of byte offset and bit offset.
    ///
    private func offset(for index: Int) -> (Int, Int) {
        let byteOffset = index / 8
        let bitOffset = 7 - index % 8
        return (byteOffset, bitOffset)
    }

    /// Returns a tuple `(byteOffset, bitOffset)` for the specified raster index.
    /// - Parameters:
    ///  - index: The raster index of the cell's coordinates, which is `y * width + x`.
    /// - Returns: A tuple of byte offset and bit offset.
    ///
    private func offset(at location: Location, in grid: Grid) -> (Int, Int) {
        let index = location.y * grid.width + location.x
        return offset(for: index)
    }
}

// MARK: Statistics
extension Layout {
    public var score: (Int, Int) {
        scoreCache.score(of: self)
    }
    
    /// Score of the layout.
    ///
    /// Score is a tuple of the number of intersections and the number
    /// of white cells. Higher score suggests more interesting and
    /// dence puzzle.
    func computeScore() -> (Int, Int) {
        var intersectionCount = 0
        var whiteCellCount = 0
        for location in Locations(grid: grid) {
            guard cell(at: location) == .white else {
                continue
            }
            whiteCellCount += 1

            // Is this location horizontally spanning?
            let locationLeft = location - (-1, 0)
            let locationRight = location - (+1, 0)
            let horizontallySpanning =
                (grid.contains(locationLeft) && cell(at: locationLeft) == .white)
                || (grid.contains(locationRight) && cell(at: locationRight) == .white)

            // Is this location vertially spanning?
            let locationUp = location - (0, -1)
            let locationDown = location - (0, +1)
            let verticallySpanning =
                (grid.contains(locationUp) && cell(at: locationUp) == .white)
                || (grid.contains(locationDown) && cell(at: locationDown) == .white)

            if horizontallySpanning && verticallySpanning {
                intersectionCount += 1
            }
        }
        return (intersectionCount, whiteCellCount)
    }
}

/// Representations
extension Layout {
    /// Layout as Data.
    var dataRepresentation: Data {
        Data(storage)
    }

    /// List of black cell locations.
    func blackCells() -> [Location] {
        var blackCells = [Location]()
        for location in Locations(grid: grid) {
            if cell(at: location) == .black {
                blackCells.append(location)
            }
        }
        return blackCells
    }
}

/// Static utility functions
extension Layout {
    /// Number of bytes necessary to store this layout.
    static func storageSize(for grid: Grid) -> Int {
        let cellCount = grid.width * grid.height
        let storageSize = (cellCount + 7) / 8
        return storageSize
    }
}

fileprivate class ScoreCacheWrapper: @unchecked Sendable {
    private let cachedValue = Mutex<(Int, Int)?>(nil)
    func score(of layout: Layout) -> (Int, Int) {
        cachedValue.withLock { current in
            if let current {
                return current
            }
            let newValue = layout.computeScore()
            current = newValue
            return newValue
        }
    }
}
