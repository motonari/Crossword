public struct Grid: Equatable, Sendable {
    public let width: Int
    public let height: Int

    public init(width: Int, height: Int) {
        guard width > 0, height > 0 else {
            fatalError("width and height must be greater than 0.")
        }

        self.width = width
        self.height = height
    }

    func contains(_ location: Location) -> Bool {
        (0 <= location.x && location.x < width) && (0 <= location.y && location.y < height)
    }
}
