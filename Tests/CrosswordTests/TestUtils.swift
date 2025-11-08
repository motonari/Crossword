import Testing

func testElementsEquality<S: Sequence>(_ seq1: S, _ seq2: S) -> Bool where S.Element: Equatable {
    let array1 = Array(seq1)
    let array2 = Array(seq2)
    if array1.count != array2.count {
        Issue.record("Length mismatch")
        return false
    }

    var result = true
    var index = 0
    zip(array1, array2).forEach { (e1, e2) in
        if e1 != e2 {
            Issue.record("Mismatch at index = \(index)")
            result = false
        }
        index += 1
    }
    return result
}
