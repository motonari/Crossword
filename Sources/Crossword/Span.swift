import CryptoKit

/// Row or column span in the grid, where a word will be placed.
struct Span {
    let start: Location
    let length: Int
    let direction: Direction

    let range: (Range<Int>, Range<Int>)
    let startEdge: Location
    let end: Location
}

// Initializers
extension Span {
    /// Creates a span for a specified location, length, and
    /// direction.
    ///
    /// - Parameters:
    ///   - start: The starting location of the span.
    ///   - length: The lenght of the span.
    ///   - direction: The direction of the span.
    init(at start: Location, length: Int, direction: Direction) {
        self.start = start
        self.length = length
        self.direction = direction

        self.startEdge = start - direction.delta
        self.end = start + (direction.deltaX * length, direction.deltaY * length)

        self.range = Self.spanRange(start, length, direction)
    }

    /// Creates a span for a specified coordinates, length, and
    /// direction.
    ///
    /// - Parameters:
    ///   - coordinates: The starting coordinates of the span.
    ///   - length: The lenght of the span.
    ///   - direction: The direction of the span.
    init(at coordinates: (Int, Int), length: Int, direction: Direction) {
        self.init(
            at: Location(coordinates),
            length: length,
            direction: direction)
    }

    private static func spanRange(_ start: Location, _ length: Int, _ direction: Direction) -> (
        Range<Int>, Range<Int>
    ) {
        switch direction {
        case .across:
            let spanX = start.x..<(start.x + length)
            let spanY = start.y..<(start.y + 1)
            return (spanX, spanY)
        case .down:
            let spanX = start.x..<(start.x + 1)
            let spanY = start.y..<(start.y + length)
            return (spanX, spanY)
        }
    }
}

/// Equatable and Hashable implementation.
///
/// We need an explicit implementation because `Span` has some cached
/// properties.
extension Span: Equatable, Hashable {
    static func == (lhs: Span, rhs: Span) -> Bool {
        lhs.start == rhs.start && lhs.length == rhs.length && lhs.direction == rhs.direction
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(start)
        hasher.combine(length)
        hasher.combine(direction)
    }
}
/// Comparable implementation
///
/// We need an explicit implementation because `Span` has some cached
/// properties.
extension Span: Comparable {
    static func < (lhs: Span, rhs: Span) -> Bool {
        if lhs.start != rhs.start {
            return lhs.start < rhs.start
        }

        if lhs.length != rhs.length {
            return lhs.length < rhs.length
        }

        if lhs.direction != rhs.direction {
            return lhs.direction < rhs.direction
        }

        return false
    }
}

/// String convertible
extension Span: CustomStringConvertible, CustomDebugStringConvertible {
    var debugDescription: String {
        "Span(at: \(start), length: \(length), direction: \(direction))"
    }

    var description: String {
        "Span(\(start) -> \(end))"
    }
}

/// SHA-256 hash support
extension Span {
    func hash<F: HashFunction>(into hasher: inout F) {
        var data = [UInt8](repeating: 0, count: 2 + 1 + 1)
        data[0] = UInt8(start.x)
        data[1] = UInt8(start.y)
        data[2] = UInt8(length)
        data[3] = UInt8(direction == .across ? 0 : 1)
        hasher.update(data: data)
    }
}

/// Intersecting test
extension Span {
    /// Returns the position of intersecting cell with the other
    /// span, or `nil` if they do not intersect.
    ///
    /// Two spans of a same direction do not intersect even if they
    /// overlap.
    ///
    /// For example,
    /// ```
    ///  R
    ///  O
    /// CAT
    ///  D
    /// ```
    /// `Span("ROAD").intersects(with: Span("CAT"))` would return `(2,
    /// 1)` because the intersecting letter (`A`) is at index 2 in
    /// "ROAD" and at index 1 in "CAT". (Note: index is 0-based.)
    ///
    /// - Parameters:
    ///  - other: The other span
    ///
    /// - Returns: The location of the intersecting cell as a tuple of
    ///  the index into the first span and the other span.
    func intersects(with other: Span) -> (Int, Int)? {
        guard direction != other.direction else {
            // Same directions; not intersecting. This also covers the
            // case self == other case.
            return nil
        }

        var indexA = 0
        var indexB = 0
        if direction == .across {
            precondition(other.direction == .down)
            let spanH = start.x..<(start.x + length)
            let spanV = other.start.y..<(other.start.y + other.length)

            if !spanH.contains(other.start.x) || !spanV.contains(start.y) {
                // Not intersecting
                return nil
            }
            indexA = other.start.x - start.x
            indexB = start.y - other.start.y
        } else if direction == .down {
            precondition(other.direction == .across)
            let spanV = start.y..<(start.y + length)
            let spanH = other.start.x..<(other.start.x + other.length)

            if !spanH.contains(start.x) || !spanV.contains(other.start.y) {
                // Not intersecting
                return nil
            }
            indexA = other.start.y - start.y
            indexB = start.x - other.start.x
        }

        return (indexA, indexB)
    }
}

/// Compatibility test
extension Span {
    /// Returns true if the span can co-exist with the other span.
    func compatible(with other: Span) -> Bool {
        guard self != other else {
            // Two equal spans cannot co-exist.
            return false
        }

        let (thisRangeX, thisRangeY) = range
        let (otherRangeX, otherRangeY) = other.range

        if thisRangeX.contains(other.startEdge.x) && thisRangeY.contains(other.startEdge.y) {
            // This span contains a cell which is prior to the other
            // span's starting cell. For example, "CAT" and "DOG"
            // cannot co-exist in this way because "ADOG" is not a word.
            //
            //  C
            //  ADOG
            //  T
            return false
        }

        if thisRangeX.contains(other.end.x) && thisRangeY.contains(other.end.y) {
            // This span contains a cell which is after the other
            // span's last cell. For example, "CAT" and "DOG" cannot
            // co-exist in this way because "DOGA" is not a word.
            //
            //     C
            //  DOGA
            //     T
            return false
        }

        if otherRangeX.contains(startEdge.x) && otherRangeY.contains(startEdge.y) {
            // Similar to above, but for the symmetric condition.
            return false
        }

        if otherRangeX.contains(end.x) && otherRangeY.contains(end.y) {
            // Similar to above, but for the symmetric condition.
            return false
        }

        return true
    }
}

extension Span {
    /// Two spans with same direction share the borders.
    func adjoining(with other: Span) -> Bool {
        guard self.direction == other.direction else {
            return false
        }

        let (thisRangeX, thisRangeY) = range
        let (otherRangeX, otherRangeY) = other.range

        if direction == .across {
            if thisRangeX.overlaps(otherRangeX)
                && (thisRangeY.lowerBound == otherRangeY.lowerBound - 1
                    || thisRangeY.lowerBound == otherRangeY.lowerBound + 1)
            {
                return true
            }
        } else {
            if thisRangeY.overlaps(otherRangeY)
                && (thisRangeX.lowerBound == otherRangeX.lowerBound - 1
                    || thisRangeX.lowerBound == otherRangeX.lowerBound + 1)
            {
                return true
            }
        }

        return false
    }
}
