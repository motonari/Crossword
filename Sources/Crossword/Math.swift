import Foundation

func normallyDistributedRandom(mean: Double, standardDeviation: Double) -> Double {
    var u = 0.0
    var s = 0.0

    while true {
        u = Double.random(in: -1.0...1.0)
        let v = Double.random(in: -1.0...1.0)

        s = u * u + v * v
        if s != 0.0 && s < 1.0 {
            break
        }
        // Discard s, try again.
    }

    let z = u * sqrt(-2.0 * log(s) / s)
    return z * standardDeviation + mean
}

func maxElementIndex(of values: [Double]) -> Int? {

    guard let maxValue = values.max() else {
        return nil
    }

    var maxElementIndices = [Int]()
    for (index, value) in values.enumerated() {
        if abs(value - maxValue) < 1e-9 {
            maxElementIndices.append(index)
        }
    }
    return maxElementIndices.randomElement()
}

// This is a fixed-increment version of Java 8's SplittableRandom generator.
// It is a very fast generator passing BigCrush, with 64 bits of state.
// See http://dx.doi.org/10.1145/2714064.2660195 and
// http://docs.oracle.com/javase/8/docs/api/java/util/SplittableRandom.html
//
// Derived from public domain C implementation by Sebastiano Vigna
// See http://xoshiro.di.unimi.it/splitmix64.c
public struct SplitMix64: RandomNumberGenerator {
    private var state: UInt64

    public init(seed: UInt64) {
        self.state = seed
    }

    public mutating func next() -> UInt64 {
        self.state &+= 0x9e37_79b9_7f4a_7c15
        var z: UInt64 = self.state
        z = (z ^ (z &>> 30)) &* 0xbf58_476d_1ce4_e5b9
        z = (z ^ (z &>> 27)) &* 0x94d0_49bb_1331_11eb
        return z ^ (z &>> 31)
    }
}
