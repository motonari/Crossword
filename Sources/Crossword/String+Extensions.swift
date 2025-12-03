extension String {
    func character(at offset: Int) -> Character {
        let index = self.index(self.startIndex, offsetBy: offset)
        return self[index]
    }
}
