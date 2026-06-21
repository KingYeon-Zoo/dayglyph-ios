import CoreGraphics
import Foundation

/// 星图中单颗「记录星」的归一化落点。`unitPosition` 取值 0...1，渲染时乘以画布尺寸。
nonisolated struct StarPlacement: Equatable {
    var date: Date
    var unitPosition: CGPoint
}

/// 把当月的记录日期确定性地散布到二维星图上。
///
/// 采用「抖动网格」：把可用画布切成 `ceil(√N)` 列的网格，每个有记录的格子放一颗星，
/// 星在格内的精确位置由 `SeededRandom` 抖动决定。这样既松散自然、星与星不重叠，
/// 又满足项目硬约束——同一月份（同 seed + 同日期集合）永远得到同一套布局。
nonisolated enum StarMapLayout {
    /// 画布四周留白（归一化）。底部留白更大，给日期标签预留空间。
    static let marginX = 0.12
    static let marginTop = 0.13
    static let marginBottom = 0.17

    static func placements(dates: [Date], seed: Int) -> [StarPlacement] {
        let sorted = dates.sorted()
        let count = sorted.count
        guard count > 0 else { return [] }

        let columns = max(Int(ceil(Double(count).squareRoot())), 1)
        let rows = max(Int(ceil(Double(count) / Double(columns))), 1)

        let usableWidth = 1 - 2 * marginX
        let usableHeight = 1 - marginTop - marginBottom
        let cellWidth = usableWidth / Double(columns)
        let cellHeight = usableHeight / Double(rows)

        var random = SeededRandom(seed: seed)

        return sorted.enumerated().map { index, date in
            let column = index % columns
            let row = index / columns
            let baseX = marginX + (Double(column) + 0.5) * cellWidth
            let baseY = marginTop + (Double(row) + 0.5) * cellHeight
            // 抖动幅度限制在格子的 ±30%，保证不越界、不与邻格重叠。
            let jitterX = (random.next() - 0.5) * cellWidth * 0.6
            let jitterY = (random.next() - 0.5) * cellHeight * 0.6
            return StarPlacement(
                date: date,
                unitPosition: CGPoint(x: baseX + jitterX, y: baseY + jitterY)
            )
        }
    }
}
