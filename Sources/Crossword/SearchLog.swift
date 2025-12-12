import CryptoKit

/// Utility to implement memorization for dynamic programming.
class SearchLog<Fingerprint: Hashable> {
    let maxCount: Int = 1000_000

    private var log = Set<Fingerprint>()

    func firstVisit(_ fingerprint: Fingerprint) -> Bool {
        let (inserted, _) = log.insert(fingerprint)
        while log.count > maxCount {
            log.removeFirst()
        }
        return inserted
    }
}
