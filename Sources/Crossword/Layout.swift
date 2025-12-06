import Foundation

/// Locations of black cells in the grid.
public struct Layout {
    private var storage: Data
}

/// In-memory initializers.
extension Layout {
    /// Creates a layout with all white cells.
    init(grid: Grid) {
        let storageSize = Self.storageSize(for: grid)
        self.storage = Data(count: storageSize)
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

            self.update(to: .black, at: location, in: grid)
        }
    }

    /// Creates a layout with specified black cells.
    ///
    /// - Parameters:
    ///  - grid: The size of the crossword.
    ///  - blackCells: List of black cell locations.
    public init(grid: Grid, blackCells: [(Int, Int)]) {
        self.init(grid: grid, blackCells: blackCells.map(Location.init))
    }
}

/// Initializers from a file
extension Layout {
    /// Creates a layout by reading byte stream from an open file
    /// handle.
    ///
    /// - Parameters:
    ///  - fileHandle: The file handle from which the object will be created.
    ///  - grid: The size of the crossword.
    init?(fileHandle: FileHandle, grid: Grid) throws {
        let bytesPerLayout = Self.storageSize(for: grid)
        guard let storage = try fileHandle.read(upToCount: bytesPerLayout) else {
            return nil
        }

        if storage.count != bytesPerLayout {
            return nil
        }

        self.storage = storage
    }
}

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

    /// Update a specified cell to black or white.
    /// - Parameters:
    ///   - color: The cell color to be set.
    ///   - location: Cell's coordinates.
    ///   - grid: The grid.
    mutating func update(to color: Color, at location: Location, in grid: Grid) {
        let (byteOffset, bitOffset) = offset(at: location, in: grid)
        guard byteOffset < storage.count else {
            fatalError("Out of bound location: \(location)")
        }

        let bits = storage[byteOffset]
        let newBits =
            if color == .black {
                bits | (0x01 << bitOffset)
            } else {
                bits & ~(0x01 << bitOffset)
            }

        storage[byteOffset] = newBits
    }

    /// Returns cell's color
    /// - Parameters:
    ///   - location: Cell's coordinates.
    ///   - grid: The grid.
    func cell(at location: Location, in grid: Grid) -> Color {
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

/// The number of intersections
extension Layout {
    public func intersectionCount(in grid: Grid) -> Int {
        var count = 0
        for location in Locations(grid: grid) {
            guard cell(at: location, in: grid) == .white else {
                continue
            }

            // Is this location horizontally spanning?
            let locationLeft = location - (-1, 0)
            let locationRight = location - (+1, 0)
            let horizontallySpanning =
                (grid.contains(locationLeft) && cell(at: locationLeft, in: grid) == .white)
                || (grid.contains(locationRight) && cell(at: locationRight, in: grid) == .white)

            // Is this location vertially spanning?
            let locationUp = location - (0, -1)
            let locationDown = location - (0, +1)
            let verticallySpanning =
                (grid.contains(locationUp) && cell(at: locationUp, in: grid) == .white)
                || (grid.contains(locationDown) && cell(at: locationDown, in: grid) == .white)

            if horizontallySpanning && verticallySpanning {
                count += 1
            }
        }
        return count
    }
}

/// Representations
extension Layout {
    /// Layout as Data.
    var dataRepresentation: Data {
        storage
    }

    /// List of black cell locations.
    func blackCells(in grid: Grid) -> [Location] {
        var blackCells = [Location]()
        for location in Locations(grid: grid) {
            if cell(at: location, in: grid) == .black {
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
