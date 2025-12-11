import CryptoKit

protocol Digestable {
    var digest: SHA256.Digest { get }
}

/// Utility to implement memorization for dynamic programming.
class SearchLog<D: Digestable> {
    let maxCount: Int = 1000_000

    private var log = Set<SHA256.Digest>()

    func firstVisit(_ state: D) -> Bool {
        let (inserted, _) = log.insert(state.digest)
        if log.count > maxCount {
            log.removeFirst()
        }
        return inserted
    }
}
