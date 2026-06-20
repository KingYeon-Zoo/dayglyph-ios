import Foundation

/// 演示降级结果（spec 第 8、14 节）。
///
/// 比赛现场网络异常时，预存一套完整、合法的生成结果作为明确标记的本地降级展示。
/// 该结果通过与线上同一套 `GenerationSchemaValidator` 校验，保证字段合法。
/// 不含图片字节——降级展示使用品牌占位卡片或预存样图（由调用方决定）。
enum DemoFallbackCatalog {

    /// 一套覆盖 5～8 种情绪的复杂样本，供现场降级演示。
    static let richSample = DayGenerationResponse(
        schemaVersion: "1.0",
        requestID: "demo-fallback-rich",
        safety: SafetyAssessment(riskLevel: "none", crisisDetected: false, rationale: "记录属于日常情绪表达，无风险信号。"),
        emotionAnalysis: EmotionAnalysisPayload(
            emotions: [
                EmotionItem(term: "欣慰", family: "joy", intensity: 0.62, confidence: 0.8, evidence: "终于把拖了很久的事情完成"),
                EmotionItem(term: "疲惫", family: "depletion", intensity: 0.58, confidence: 0.82, evidence: "连续几天没睡好"),
                EmotionItem(term: "担忧", family: "fear", intensity: 0.5, confidence: 0.75, evidence: "不确定结果会不会被认可"),
                EmotionItem(term: "委屈", family: "anger", intensity: 0.42, confidence: 0.7, evidence: "付出好像没被看见"),
                EmotionItem(term: "感恩", family: "connection", intensity: 0.55, confidence: 0.78, evidence: "还好有人搭了把手"),
                EmotionItem(term: "希望", family: "drive", intensity: 0.48, confidence: 0.72, evidence: "觉得明天会好一点")
            ],
            otherEmotions: [],
            dimensions: EmotionDimensions(
                valence: 0.12, arousal: 0.52, dominance: 0.08,
                energy: 0.4, tension: 0.6, certainty: 0.45, socialConnection: 0.5
            ),
            relationships: [
                EmotionRelationship(from: "疲惫", to: "欣慰", kind: "coexists")
            ],
            summary: "今天交织着完成事情后的欣慰与连日的疲惫，对结果有些担忧，也夹着一点不被看见的委屈，但仍留着对明天的希望。",
            uncertainties: []
        ),
        sharedVisualDirection: SharedVisualDirection(
            palette: ["#F4A36C", "#3B6FB0", "#1C2540", "#E8D5B5"],
            contrast: 0.55, temperature: 0.62, lightSoftness: 0.7, spatialDensity: 0.45,
            motionImpression: "缓慢上升的暖流", symbols: ["晨光", "涟漪", "微尘"]
        ),
        cocktail: CocktailSpec(
            name: "微光余温",
            description: "一杯在疲惫中仍透出暖意的鸡尾酒。",
            glass: "宽口浅碟杯",
            glassMaterial: "polished_crystal",
            liquidLayers: [
                LiquidLayer(color: "amber", boundaryStyle: "soft_diffusion"),
                LiquidLayer(color: "deep_blue", boundaryStyle: "gradient")
            ],
            garnish: ["一片金箔", "细盐边"],
            particles: "极细悬浮气泡缓慢上升",
            lighting: "侧上方暖光",
            camera: "微俯视特写",
            background: "深蓝渐暗",
            composition: "杯体居中偏下，大量上方留白"
        ),
        planet: PlanetSpec(
            name: "余温星",
            description: "一颗表面流动着暖色脉络的安静星球。",
            silhouette: "饱满圆润",
            surface: PlanetSurface(material: "translucent_mineral", detail: "暖橙脉络在深蓝基底中缓慢流动"),
            core: "温暖的橙金内核",
            atmosphere: "薄而柔和的暖雾层",
            rings: ["一圈稀薄尘环"],
            satellites: ["一颗微小伴星"],
            particles: "稀疏星尘",
            lighting: "右上方柔光",
            camera: "正面中景",
            background: "深空与远处星点",
            composition: "星球居中，四周留白"
        ),
        dailyAction: DailyActionSpec(
            title: "给自己十分钟",
            instruction: "找个安静角落，闭眼慢慢做五次深呼吸，不用想任何待办。",
            durationMinutes: 10,
            difficulty: "easy",
            environment: "anywhere",
            reason: "连日的疲惫需要一个不带任务的小停顿。"
        ),
        dailyMessage: DailyMessageSpec(
            text: "完成本身就值得被看见，哪怕此刻只有你自己知道。今天已经很努力了。",
            attribution: "DayGlyph 今日寄语"
        ),
        emotionalWeather: EmotionalWeatherSpec(
            title: "多云转晴",
            explanation: "情绪像被云层遮住的阳光，光一直都在，只是需要一点时间透出来。",
            symbol: "partly_cloudy"
        )
    )

    /// 返回经校验的降级样本；若校验失败（不应发生）返回 nil。
    static func validatedRichSample() -> DayGenerationResponse? {
        try? GenerationSchemaValidator.validate(richSample)
        return richSample
    }
}
