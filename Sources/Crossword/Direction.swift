enum Direction: Comparable, CaseIterable {
    case across
    case down

    var delta: (Int, Int) {
        switch self {
        case .across: (1, 0)
        case .down: (0, 1)
        }
    }

    var deltaX: Int {
        switch self {
        case .across: 1
        case .down: 0
        }
    }

    var deltaY: Int {
        switch self {
        case .across: 0
        case .down: 1
        }
    }

    var toggled: Direction {
        self == .across ? .down : .across
    }
}
