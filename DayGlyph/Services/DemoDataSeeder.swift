import Foundation
import SwiftData

enum DemoDataSeeder {
    static let samples = [
        "今天终于把拖了很久的项目收尾了，心里松了一口气。",
        "和朋友聊了很久，发现自己其实被理解着。",
        "睡得不好，一整天都有点累，只想早点休息。",
        "早上散步的时候很平静，风吹过来的时候觉得刚刚好。",
        "会议有点多，压力也上来了，但我还是撑住了。",
        "看完一本书，突然对接下来的方向更清楚了。",
        "和家人吃饭，很普通，但很安心。",
        "今天灵感很好，画了几个之前一直想做的草图。",
        "有一点低落，说不上原因，只是想慢一点。",
        "收到客户确认，大家一起努力终于有结果了。"
    ]

    static func seed(into context: ModelContext, calendar: Calendar = .current) {
        clearDemoEntries(in: context)
        let analyzer = EmotionAnalyzer()

        for offset in 0..<30 {
            guard let date = calendar.date(byAdding: .day, value: -offset, to: .now) else { continue }
            let text = samples[offset % samples.count]
            let analysis = analyzer.analyze(text)
            let seed = GlyphSignature.seed(for: text, date: date, calendar: calendar)
            let entry = DayEntry(
                date: date,
                text: text,
                emotion: analysis.emotion,
                energy: analysis.energy,
                theme: analysis.theme,
                keywords: analysis.keywords,
                glyphSeed: seed,
                isDemo: true
            )
            context.insert(entry)
        }
        try? context.save()
    }

    static func clearDemoEntries(in context: ModelContext) {
        let descriptor = FetchDescriptor<DayEntry>(predicate: #Predicate { $0.isDemo == true })
        let entries = (try? context.fetch(descriptor)) ?? []
        entries.forEach(context.delete)
        try? context.save()
    }

    static func clearAllEntries(in context: ModelContext) {
        let descriptor = FetchDescriptor<DayEntry>()
        let entries = (try? context.fetch(descriptor)) ?? []
        entries.forEach(context.delete)
        try? context.save()
    }
}
