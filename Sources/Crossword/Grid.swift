struct Grid {
    init(width: Int, height: Int) {
        guard 3 <= width else {
            fatalError("Grid width must be 3 or greater.")
        }

        guard 3 <= height else {
            fatalError("Grid height must be 3 or greater.")
        }

        self.width = width
        self.height = height
    }

    let width: Int
    let height: Int
}
