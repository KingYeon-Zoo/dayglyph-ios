enum UniversePresentation {
    static func monthSummary(recordCount: Int) -> String {
        if recordCount == 1 {
            return "这个月有 1 个记录日，数据还少。"
        }
        return "这个月有 \(recordCount) 个记录日，共同组成了这颗月星球。"
    }

    static func complexityDescription(_ value: Double) -> String {
        if value < 0.35 { return "内部层次较轻" }
        if value < 0.70 { return "内部层次交错" }
        return "内部层次丰富"
    }
}
