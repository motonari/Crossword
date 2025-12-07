import Testing

@testable import Crossword

@Suite struct DomainTests {
    func nodeConsistencyInitialization() throws {
        let span = Span(at: (0, 0), length: 3, direction: .across)
        let wordList = ["ON", "CAT", "DOG", "RABBIT"].map(Word.init)
        let domain = try #require(Domain(for: span, using: wordList))

        #expect(domain.stringArrayRepresentation == ["CAT", "DOG"])
    }

}
