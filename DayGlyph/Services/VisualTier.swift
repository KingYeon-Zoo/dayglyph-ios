import Foundation

/// 离散视觉档位（spec 第 7 节：数值先映射到离散视觉档位，避免连续值噪声）。
///
/// 连续 JSON 数值先落到有限档位，保证同版本同输入产生稳定提示词。
enum VisualTier {
    static func temperature(_ value: Double) -> String {
        switch value {
        case ..<0.2: "清冷偏蓝"
        case ..<0.4: "微凉中性"
        case ..<0.6: "中性平衡"
        case ..<0.8: "温暖偏橙"
        default: "暖调金橙"
        }
    }

    static func softness(_ value: Double) -> String {
        switch value {
        case ..<0.25: "硬朗定向光，清晰阴影"
        case ..<0.5: "中等柔光"
        case ..<0.75: "柔和漫射光"
        default: "极柔散射光，几乎无硬阴影"
        }
    }

    static func density(_ value: Double) -> String {
        switch value {
        case ..<0.25: "极简空旷，大量负空间"
        case ..<0.5: "简洁，留白充足"
        case ..<0.75: "中等密度，层次丰富"
        default: "密集细节，元素饱满但不杂乱"
        }
    }

    static func contrast(_ value: Double) -> String {
        switch value {
        case ..<0.33: "低对比，柔和过渡"
        case ..<0.66: "中对比"
        default: "高对比，明暗分明"
        }
    }
}

/// 条件片段库（spec 第 7 节：JSON 不提供自由生图提示词，而是选择客户端维护的高质量片段）。
///
/// 把 JSON 里的离散枚举值（材质、边界风格等）映射成经过打磨的中文画面描述。
/// 未命中的值原样透传，保证模型仍可工作但优先走受控片段。
enum Fragment {
    /// 表面/杯身材质片段。
    static func material(_ token: String) -> String {
        switch token.lowercased() {
        case "translucent_mineral": "半透明矿物，内部可见细微晶体脉络"
        case "frosted_glass": "磨砂玻璃，柔和漫反射"
        case "polished_crystal": "抛光水晶，清透折射"
        case "liquid_metal": "液态金属，流动镜面光泽"
        case "soft_ceramic": "柔润陶瓷，哑光表面"
        case "molten_glass": "熔融玻璃，温润流动质感"
        case "iridescent": "虹彩薄膜，随角度变幻色泽"
        case "nebula_dust": "星云尘埃，朦胧颗粒感"
        case "ice_crystal": "冰晶，透亮带霜"
        default: token
        }
    }

    /// 液体层边界风格片段。
    static func boundary(_ token: String) -> String {
        switch token.lowercased() {
        case "soft_diffusion": "颜色边界缓慢扩散，保持清晰层次，不形成浑浊混色"
        case "sharp": "颜色边界锐利分明"
        case "gradient": "颜色平滑渐变过渡"
        case "swirl": "颜色轻柔旋涡交融，仍保留主次"
        default: token
        }
    }

    /// 颜色 token 片段：hex 原样，英文色彩词转中文倾向描述。
    static func color(_ token: String) -> String {
        if token.hasPrefix("#") { return token }
        return switch token.lowercased() {
        case "amber": "琥珀橙"
        case "deep_blue", "deepblue": "深邃蓝"
        case "rose": "玫瑰粉"
        case "teal": "青碧"
        case "violet": "紫罗兰"
        case "gold": "暖金"
        case "emerald": "翡翠绿"
        case "coral": "珊瑚橘"
        case "indigo": "靛蓝"
        case "blush": "微醺粉"
        default: token
        }
    }
}

/// 稳定哈希（spec 第 7 节：同一 JSON 与模板版本产生相同提示词和哈希）。
enum StableHash {
    static func fnv1a(_ string: String) -> String {
        var hash: UInt64 = 0xcbf29ce484222325
        for byte in string.utf8 {
            hash ^= UInt64(byte)
            hash = hash &* 0x100000001b3
        }
        return String(hash, radix: 16)
    }
}
