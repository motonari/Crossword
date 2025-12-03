import Testing

@testable import Crossword

@Suite struct DomainTests {
    func nodeConsistencyInitialization() {
        let span = Span(at: (0, 0), length: 3, direction: .across)
        let wordList = ["ON", "CAT", "DOG", "RABBIT"]
        let domain = Domain(for: span, using: wordList)

        #expect(domain.values == ["CAT", "DOG"])
    }

}
