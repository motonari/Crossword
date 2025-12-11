struct SpanPair: Equatable, Hashable {
    let span1: Span
    let span2: Span
    init(_ span1: Span, _ span2: Span) {
        self.span1 = span1
        self.span2 = span2
    }
}

extension SpanPair: Comparable {
    static func < (lhs: SpanPair, rhs: SpanPair) -> Bool {
        if lhs.span1 != rhs.span1 {
            return lhs.span1 < rhs.span1
        }

        if lhs.span2 != rhs.span2 {
            return lhs.span2 < rhs.span2
        }

        return false
    }

}
