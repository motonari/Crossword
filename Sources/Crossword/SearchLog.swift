import CryptoKit

protocol Digestable {
    var digest: SHA256.Digest { get }
}

/// Utility to implement memorization for dynamic programming.
class SearchLog<D: Digestable> {
    private var log = Set<SHA256.Digest>()

    func firstVisit(_ state: D) -> Bool {
        let (inserted, _) = log.insert(state.digest)
        return inserted
    }
}
