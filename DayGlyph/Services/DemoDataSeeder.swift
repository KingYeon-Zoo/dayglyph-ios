import Foundation
import SwiftData

enum DemoDataSeeder {
    struct Sample {
        var text: String
        var analysis: EmotionAnalysis
    }

    static let samples: [Sample] = [
        sample(
            "早上散步的时候很安静，风吹过来，感觉一切都刚刚好。",
            valence: 0.42, arousal: 0.22, dominance: 0.36,
            primary: .calm, secondary: .relief, theme: .rest,
            explanation: "低唤醒和稳定感让边界柔和闭合，节律保持均匀。"
        ),
        sample(
            "团队终于把困难的问题解决了，大家笑得停不下来。",
            valence: 0.88, arousal: 0.7, dominance: 0.58,
            primary: .joy, secondary: .excited, theme: .work,
            explanation: "明显的愉悦和较高唤醒让轨迹上扬，节律变得明亮活跃。"
        ),
        sample(
            "朋友特地绕路来陪我，想到这件事还是觉得很温暖。",
            valence: 0.82, arousal: 0.38, dominance: 0.3,
            primary: .grateful, secondary: .joy, theme: .relationship,
            explanation: "温暖的正向感受让核心靠近整体，外层形成包裹关系。"
        ),
        sample(
            "拖了很久的项目终于交付，肩膀一下子松了下来。",
            valence: 0.56, arousal: 0.27, dominance: 0.5,
            primary: .relief, secondary: .calm, theme: .work,
            explanation: "压力释放后唤醒度下降，边界打开，轨迹逐渐舒展。"
        ),
        sample(
            "读完那封回复后，我第一次觉得接下来的方向真的有可能。",
            valence: 0.7, arousal: 0.52, dominance: 0.34,
            primary: .hopeful, secondary: .joy, theme: .growth,
            explanation: "正向期待让轨迹向上，核心略微抬升并向外连接。"
        ),
        sample(
            "方案通过的那一刻特别激动，脑子里一下冒出好多新想法。",
            valence: 0.78, arousal: 0.94, dominance: 0.62,
            primary: .excited, secondary: .joy, theme: .creativity,
            explanation: "高唤醒和正向情绪让节律密集外扩，轨迹快速上扬。"
        ),
        sample(
            "对方又临时推翻已经确认的内容，我真的很生气。",
            valence: -0.82, arousal: 0.91, dominance: 0.68,
            primary: .angry, secondary: .confused, theme: .work,
            explanation: "高唤醒和较强掌控感让边界尖锐收紧，节律向外爆发。"
        ),
        sample(
            "明天要公开汇报，越想越担心，脑子一直停不下来。",
            valence: -0.72, arousal: 0.86, dominance: -0.58,
            primary: .anxious, secondary: .confused, theme: .work,
            explanation: "高唤醒与低掌控感让边界偏心，轨迹持续摆动交叉。"
        ),
        sample(
            "告别之后回到家，安静下来才发现自己真的很难过。",
            valence: -0.86, arousal: 0.34, dominance: -0.62,
            primary: .sad, secondary: .lonely, theme: .relationship,
            explanation: "负向低唤醒让轨迹和核心下沉，外部节律变得稀疏。"
        ),
        sample(
            "昨晚几乎没睡，今天整个人像被抽空，只想早点躺下。",
            valence: -0.48, arousal: 0.12, dominance: -0.55,
            primary: .tired, secondary: .sad, theme: .rest,
            explanation: "极低唤醒让图形压低收敛，节律数量减少并失去张力。"
        ),
        sample(
            "大家都很忙，我不想打扰谁，但今天确实有一点孤单。",
            valence: -0.7, arousal: 0.24, dominance: -0.68,
            primary: .lonely, secondary: .sad, theme: .relationship,
            explanation: "孤独感让核心与边界拉开距离，周围节律保持留白。"
        ),
        sample(
            "事情似乎在变好，可我又说不清自己到底期待还是害怕。",
            valence: -0.04, arousal: 0.62, dominance: -0.42,
            primary: .confused, secondary: .anxious, theme: .growth,
            explanation: "相互拉扯的情绪让轨迹交叉，边界和节律出现不规则偏移。"
        )
    ]

    static func seed(into context: ModelContext, calendar: Calendar = .current) {
        clearDemoEntries(in: context)

        let realDescriptor = FetchDescriptor<DayEntry>(predicate: #Predicate { $0.isDemo == false })
        let occupiedDays = Set(
            ((try? context.fetch(realDescriptor)) ?? [])
                .map { calendar.startOfDay(for: $0.date) }
        )

        var demoCount = 0
        var offset = 0
        while demoCount < 30, offset < 90 {
            defer { offset += 1 }
            guard let date = calendar.date(byAdding: .day, value: -offset, to: .now) else { continue }
            let day = calendar.startOfDay(for: date)
            guard !occupiedDays.contains(day) else { continue }

            let fixture = samples[demoCount % samples.count]
            _ = try? DayEntryStore.saveEntry(
                text: fixture.text,
                date: day,
                analysis: fixture.analysis,
                context: context,
                calendar: calendar,
                isDemo: true
            )
            demoCount += 1
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

    private static func sample(
        _ text: String,
        valence: Double,
        arousal: Double,
        dominance: Double,
        primary: EmotionAnchor,
        secondary: EmotionAnchor,
        theme: DayTheme,
        explanation: String
    ) -> Sample {
        Sample(
            text: text,
            analysis: EmotionAnalysis(
                valence: valence,
                arousal: arousal,
                dominance: dominance,
                emotionWeights: [
                    EmotionWeight(anchor: primary, value: 0.76),
                    EmotionWeight(anchor: secondary, value: 0.24)
                ],
                theme: theme,
                keywords: [primary.title, secondary.title, theme.title],
                confidence: 0.88,
                explanation: explanation,
                source: .demoFixture
            )
        )
    }
}
