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
