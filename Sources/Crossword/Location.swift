public struct Location {
    var x: Int
    var y: Int

    init(_ x: Int, _ y: Int) {
        self.x = x
        self.y = y
    }

    init(_ pair: (Int, Int)) {
        self.init(pair.0, pair.1)
    }

    public static func + (lhs: Location, rhs: (Int, Int)) -> Location {
        return Location(lhs.x + rhs.0, lhs.y + rhs.1)
    }

    public static func - (lhs: Location, rhs: (Int, Int)) -> Location {
        return Location(lhs.x - rhs.0, lhs.y - rhs.1)
    }

    public static func - (lhs: Location, rhs: Location) -> (Int, Int) {
        return (lhs.x - rhs.x, lhs.y - rhs.y)
    }

    public static func += (lhs: inout Location, delta: (Int, Int)) {
        lhs.x += delta.0
        lhs.y += delta.1
    }

    public static func -= (lhs: inout Location, delta: (Int, Int)) {
        lhs.x -= delta.0
        lhs.y -= delta.1
    }
}

extension Location: Comparable {
    public static func < (lhs: Location, rhs: Location) -> Bool {
        if lhs.x != rhs.x {
            return lhs.x < rhs.x
        }

        if lhs.y != rhs.y {
            return lhs.y < rhs.y
        }

        return false
    }

}

extension Location: Hashable {
}

extension Location: CustomStringConvertible {
    public var description: String {
        "\(x), \(y)"
    }
}
