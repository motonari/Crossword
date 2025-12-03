public struct Placement: Equatable, Comparable, Hashable {

    let word: String
    let start: Location
    let direction: Direction

    public static func < (lhs: Placement, rhs: Placement) -> Bool {
        if lhs.word != rhs.word {
            return lhs.word < rhs.word
        }

        if lhs.start != rhs.start {
            return lhs.start < rhs.start
        }

        if lhs.direction != rhs.direction {
            return lhs.direction < rhs.direction
        }

        return false
    }

    func contains(_ location: Location) -> Bool {
        let (xrange, yrange) =
            switch direction {
            case .across:
                (
                    start.x..<(start.x + word.count + 1),
                    start.y..<start.y + 1
                )
            case .down:
                (
                    start.x..<start.y + 1,
                    start.y..<(start.y + word.count + 1)
                )
            }

        return xrange.contains(location.x) && yrange.contains(location.y)
    }

    var span: (Range<Int>, Range<Int>) {
        switch direction {
        case .across:
            (
                start.x..<(start.x + word.count),
                start.y..<start.y + 1
            )
        case .down:
            (
                start.x..<start.x + 1,
                start.y..<(start.y + word.count)
            )
        }

    }

    private func crossStringIndices(with other: Placement) -> (String.Index, String.Index) {
        var result: (String.Index, String.Index)
        switch self.direction {
        case .across:
            let offsetA = other.start.x - start.x
            let offsetB = start.y - other.start.y

            result = (
                word.index(word.startIndex, offsetBy: offsetA),
                other.word.index(other.word.startIndex, offsetBy: offsetB)
            )
        case .down:
            let offsetA = other.start.y - start.y
            let offsetB = start.x - other.start.x

            result = (
                word.index(word.startIndex, offsetBy: offsetA),
                other.word.index(other.word.startIndex, offsetBy: offsetB)
            )
        }
        return result
    }

    private func overlapping(with other: Placement) -> Bool {
        let (xRangeA, yRangeA) = span
        let (xRangeB, yRangeB) = other.span

        return xRangeA.overlaps(xRangeB) && yRangeA.overlaps(yRangeB)
    }

    func crossing(with other: Placement) -> Bool {
        guard overlapping(with: other) else {
            // Not overlapping; they are not crossing.
            return false
        }

        guard direction != other.direction else {
            // Same direction; not crossing
            return false
        }

        return true
    }

    func compatible(with other: Placement) -> Bool {
        guard overlapping(with: other) else {
            // Not overlapping; they are compatible.
            return true
        }

        guard direction != other.direction else {
            // Same direction; not compatible
            return false
        }

        let (crossIndexA, crossIndexB) = crossStringIndices(with: other)
        if word[crossIndexA] == other.word[crossIndexB] {
            return true
        }

        return false
    }
}
