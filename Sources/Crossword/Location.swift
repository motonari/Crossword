struct Location: Comparable {
    let x: Int
    let y: Int

    static func < (lhs: Location, rhs: Location) -> Bool {
        if lhs.x != rhs.x {
            return lhs.x < rhs.x
        }

        if lhs.y != rhs.y {
            return lhs.y < rhs.y
        }

        return false
    }
}
