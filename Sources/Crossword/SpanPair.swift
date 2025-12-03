struct SpanPair: Equatable, Hashable {
    let span1: Span
    let span2: Span
    init(_ span1: Span, _ span2: Span) {
        self.span1 = span1
        self.span2 = span2
    }
}
