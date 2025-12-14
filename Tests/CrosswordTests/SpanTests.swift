import Testing

@testable import Crossword

@Suite struct SpanTests {
    @Test func nonIntersectingSpans() {
        // AA
        // BB
        //  C
        //  C
        let spanA = Span(at: (0, 0), length: 2, direction: .across)
        let spanB = Span(at: (0, 1), length: 2, direction: .across)
        let spanC = Span(at: (1, 2), length: 2, direction: .down)

        #expect(spanA.intersects(with: spanB) == nil)
        #expect(spanB.intersects(with: spanC) == nil)
        #expect(spanC.intersects(with: spanA) == nil)
    }

    @Test func intersectingSpans() throws {
        //   B
        // AAX
        //   B
        let spanA = Span(at: (0, 1), length: 3, direction: .across)
        let spanB = Span(at: (2, 0), length: 3, direction: .down)

        let overlapAB = try #require(spanA.intersects(with: spanB))
        #expect(overlapAB == (2, 1))

        let overlapBA = try #require(spanB.intersects(with: spanA))
        #expect(overlapBA == (1, 2))
    }

    @Test func nonIntersectingSpansDifferenceLength() throws {
        //    A
        // BB#A
        //    A
        //    A
        let spanA = Span(at: (3, 0), length: 4, direction: .down)
        let spanB = Span(at: (0, 1), length: 2, direction: .across)

        #expect(spanA.intersects(with: spanB) == nil)
    }

    @Test func adjoining() throws {
        // AAA
        // BBB
        let spanA = Span(at: (0, 0), length: 3, direction: .across)
        let spanB = Span(at: (0, 1), length: 3, direction: .across)
        #expect(spanA.adjoining(with: spanB))
        #expect(spanB.adjoining(with: spanA))
    }

}
