import Foundation

struct SeededRandom {
    private var state: UInt64

    init(seed: Int) {
        self.state = UInt64(bitPattern: Int64(seed == 0 ? 0x9E3779B9 : seed))
    }

    mutating func next() -> Double {
        state = 2862933555777941757 &* state &+ 3037000493
        return Double(state % 10_000) / 10_000.0
    }
}
