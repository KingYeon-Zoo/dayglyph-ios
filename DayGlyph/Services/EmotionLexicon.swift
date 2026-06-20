import Foundation

/// 情绪族（spec 5.1）。覆盖十大类：喜悦与满足、悲伤与失去、恐惧与不安、
/// 愤怒与受挫、羞耻与内疚、关系与归属、低能量与耗竭、平静与恢复、希望与驱动力、困惑与认知冲突。
enum EmotionFamily: String, Codable, CaseIterable, Sendable {
    case joy            // 喜悦与满足
    case sadness        // 悲伤与失去
    case fear           // 恐惧与不安
    case anger          // 愤怒与受挫
    case shame          // 羞耻与内疚
    case connection     // 关系与归属
    case depletion      // 低能量与耗竭
    case calm           // 平静与恢复
    case drive          // 希望与驱动力
    case confusion      // 困惑与认知冲突

    var title: String {
        switch self {
        case .joy: "喜悦与满足"
        case .sadness: "悲伤与失去"
        case .fear: "恐惧与不安"
        case .anger: "愤怒与受挫"
        case .shame: "羞耻与内疚"
        case .connection: "关系与归属"
        case .depletion: "低能量与耗竭"
        case .calm: "平静与恢复"
        case .drive: "希望与驱动力"
        case .confusion: "困惑与认知冲突"
        }
    }

    /// 情绪族到现有 12 锚点的隐藏兼容投影（spec 5.1：为统计与 RealityKit 聚合服务）。
    var anchor: EmotionAnchor {
        switch self {
        case .joy: .joy
        case .sadness: .sad
        case .fear: .anxious
        case .anger: .angry
        case .shame: .sad
        case .connection: .grateful
        case .depletion: .tired
        case .calm: .calm
        case .drive: .hopeful
        case .confusion: .confused
        }
    }
}

/// 单个标准心理词条目。`valence/arousal/dominance` 为该词的典型 VAD 贡献（spec 5.1）。
struct EmotionLexiconEntry: Sendable, Equatable {
    var term: String
    var family: EmotionFamily
    var valence: Double      // -1 负向 … 1 正向
    var arousal: Double      // 0 低唤醒 … 1 高唤醒
    var dominance: Double    // -1 失控 … 1 掌控
}

/// 受控心理词库（spec 第 12 条）。约 80 个标准词，覆盖十大情绪族。
///
/// 常见情绪必须优先使用这里的标准词；模型无法准确表达时才写入 `other_emotions`。
/// 旧 12 类只作隐藏兼容投影（经由 `EmotionFamily.anchor` 与词条 VAD）。
enum EmotionLexicon {
    static let entries: [EmotionLexiconEntry] = [
        // 喜悦与满足
        .init(term: "喜悦", family: .joy, valence: 0.82, arousal: 0.60, dominance: 0.45),
        .init(term: "快乐", family: .joy, valence: 0.80, arousal: 0.58, dominance: 0.42),
        .init(term: "满足", family: .joy, valence: 0.72, arousal: 0.38, dominance: 0.48),
        .init(term: "欣慰", family: .joy, valence: 0.68, arousal: 0.34, dominance: 0.46),
        .init(term: "兴奋", family: .joy, valence: 0.70, arousal: 0.82, dominance: 0.50),
        .init(term: "雀跃", family: .joy, valence: 0.78, arousal: 0.78, dominance: 0.48),
        .init(term: "自豪", family: .joy, valence: 0.66, arousal: 0.55, dominance: 0.68),
        .init(term: "愉悦", family: .joy, valence: 0.74, arousal: 0.50, dominance: 0.44),

        // 悲伤与失去
        .init(term: "悲伤", family: .sadness, valence: -0.72, arousal: 0.32, dominance: -0.50),
        .init(term: "难过", family: .sadness, valence: -0.66, arousal: 0.34, dominance: -0.46),
        .init(term: "失落", family: .sadness, valence: -0.58, arousal: 0.30, dominance: -0.48),
        .init(term: "沮丧", family: .sadness, valence: -0.62, arousal: 0.40, dominance: -0.52),
        .init(term: "失望", family: .sadness, valence: -0.60, arousal: 0.36, dominance: -0.44),
        .init(term: "哀伤", family: .sadness, valence: -0.74, arousal: 0.30, dominance: -0.52),
        .init(term: "想念", family: .sadness, valence: -0.30, arousal: 0.36, dominance: -0.30),
        .init(term: "遗憾", family: .sadness, valence: -0.48, arousal: 0.32, dominance: -0.38),

        // 恐惧与不安
        .init(term: "焦虑", family: .fear, valence: -0.58, arousal: 0.72, dominance: -0.54),
        .init(term: "担忧", family: .fear, valence: -0.50, arousal: 0.60, dominance: -0.46),
        .init(term: "紧张", family: .fear, valence: -0.44, arousal: 0.70, dominance: -0.40),
        .init(term: "害怕", family: .fear, valence: -0.66, arousal: 0.74, dominance: -0.62),
        .init(term: "恐惧", family: .fear, valence: -0.72, arousal: 0.80, dominance: -0.66),
        .init(term: "不安", family: .fear, valence: -0.48, arousal: 0.62, dominance: -0.48),
        .init(term: "慌乱", family: .fear, valence: -0.54, arousal: 0.78, dominance: -0.58),
        .init(term: "忐忑", family: .fear, valence: -0.42, arousal: 0.64, dominance: -0.44),

        // 愤怒与受挫
        .init(term: "愤怒", family: .anger, valence: -0.68, arousal: 0.80, dominance: 0.30),
        .init(term: "生气", family: .anger, valence: -0.60, arousal: 0.72, dominance: 0.28),
        .init(term: "恼火", family: .anger, valence: -0.54, arousal: 0.68, dominance: 0.24),
        .init(term: "烦躁", family: .anger, valence: -0.50, arousal: 0.66, dominance: 0.10),
        .init(term: "委屈", family: .anger, valence: -0.56, arousal: 0.52, dominance: -0.36),
        .init(term: "不满", family: .anger, valence: -0.48, arousal: 0.56, dominance: 0.18),
        .init(term: "挫败", family: .anger, valence: -0.58, arousal: 0.54, dominance: -0.30),
        .init(term: "气馁", family: .anger, valence: -0.52, arousal: 0.40, dominance: -0.42),

        // 羞耻与内疚
        .init(term: "羞耻", family: .shame, valence: -0.64, arousal: 0.50, dominance: -0.58),
        .init(term: "内疚", family: .shame, valence: -0.58, arousal: 0.46, dominance: -0.50),
        .init(term: "自责", family: .shame, valence: -0.60, arousal: 0.48, dominance: -0.46),
        .init(term: "尴尬", family: .shame, valence: -0.40, arousal: 0.52, dominance: -0.44),
        .init(term: "懊悔", family: .shame, valence: -0.56, arousal: 0.44, dominance: -0.42),
        .init(term: "难为情", family: .shame, valence: -0.38, arousal: 0.48, dominance: -0.40),

        // 关系与归属
        .init(term: "感恩", family: .connection, valence: 0.74, arousal: 0.40, dominance: 0.30),
        .init(term: "感动", family: .connection, valence: 0.70, arousal: 0.48, dominance: 0.20),
        .init(term: "被理解", family: .connection, valence: 0.68, arousal: 0.38, dominance: 0.34),
        .init(term: "温暖", family: .connection, valence: 0.72, arousal: 0.36, dominance: 0.32),
        .init(term: "亲密", family: .connection, valence: 0.66, arousal: 0.42, dominance: 0.30),
        .init(term: "被支持", family: .connection, valence: 0.70, arousal: 0.40, dominance: 0.36),
        .init(term: "孤独", family: .connection, valence: -0.60, arousal: 0.34, dominance: -0.46),
        .init(term: "疏离", family: .connection, valence: -0.52, arousal: 0.30, dominance: -0.40),
        .init(term: "被忽视", family: .connection, valence: -0.56, arousal: 0.40, dominance: -0.48),

        // 低能量与耗竭
        .init(term: "疲惫", family: .depletion, valence: -0.38, arousal: 0.22, dominance: -0.40),
        .init(term: "倦怠", family: .depletion, valence: -0.42, arousal: 0.20, dominance: -0.42),
        .init(term: "精疲力竭", family: .depletion, valence: -0.50, arousal: 0.24, dominance: -0.50),
        .init(term: "无力", family: .depletion, valence: -0.48, arousal: 0.20, dominance: -0.54),
        .init(term: "麻木", family: .depletion, valence: -0.30, arousal: 0.14, dominance: -0.44),
        .init(term: "空虚", family: .depletion, valence: -0.46, arousal: 0.18, dominance: -0.48),
        .init(term: "懒散", family: .depletion, valence: -0.20, arousal: 0.18, dominance: -0.28),

        // 平静与恢复
        .init(term: "平静", family: .calm, valence: 0.40, arousal: 0.24, dominance: 0.38),
        .init(term: "放松", family: .calm, valence: 0.52, arousal: 0.26, dominance: 0.40),
        .init(term: "安心", family: .calm, valence: 0.56, arousal: 0.28, dominance: 0.42),
        .init(term: "释然", family: .calm, valence: 0.58, arousal: 0.32, dominance: 0.44),
        .init(term: "宁静", family: .calm, valence: 0.46, arousal: 0.20, dominance: 0.38),
        .init(term: "舒缓", family: .calm, valence: 0.50, arousal: 0.24, dominance: 0.36),
        .init(term: "踏实", family: .calm, valence: 0.54, arousal: 0.30, dominance: 0.46),

        // 希望与驱动力
        .init(term: "希望", family: .drive, valence: 0.62, arousal: 0.50, dominance: 0.48),
        .init(term: "期待", family: .drive, valence: 0.60, arousal: 0.56, dominance: 0.44),
        .init(term: "憧憬", family: .drive, valence: 0.64, arousal: 0.52, dominance: 0.42),
        .init(term: "斗志", family: .drive, valence: 0.58, arousal: 0.66, dominance: 0.60),
        .init(term: "决心", family: .drive, valence: 0.54, arousal: 0.60, dominance: 0.64),
        .init(term: "好奇", family: .drive, valence: 0.56, arousal: 0.54, dominance: 0.40),
        .init(term: "干劲", family: .drive, valence: 0.60, arousal: 0.64, dominance: 0.58),

        // 困惑与认知冲突
        .init(term: "困惑", family: .confusion, valence: -0.20, arousal: 0.44, dominance: -0.30),
        .init(term: "迷茫", family: .confusion, valence: -0.34, arousal: 0.40, dominance: -0.40),
        .init(term: "矛盾", family: .confusion, valence: -0.26, arousal: 0.48, dominance: -0.28),
        .init(term: "犹豫", family: .confusion, valence: -0.22, arousal: 0.42, dominance: -0.32),
        .init(term: "纠结", family: .confusion, valence: -0.30, arousal: 0.50, dominance: -0.34),
        .init(term: "茫然", family: .confusion, valence: -0.32, arousal: 0.36, dominance: -0.42),
        .init(term: "复杂", family: .confusion, valence: -0.10, arousal: 0.44, dominance: -0.24)
    ]

    /// 词 → 条目 的快速索引。
    static let index: [String: EmotionLexiconEntry] = Dictionary(
        entries.map { ($0.term, $0) },
        uniquingKeysWith: { first, _ in first }
    )

    static let terms: Set<String> = Set(entries.map(\.term))

    static func entry(for term: String) -> EmotionLexiconEntry? {
        index[term]
    }

    static func isValid(_ term: String) -> Bool {
        terms.contains(term)
    }
}
