import Testing
import Foundation
@testable import DayGlyph

/// 安全短路测试（spec 第 9 节）。
@MainActor
struct SafetyPrescreenTests {

    @Test func detectsExplicitHighRisk() {
        #expect(SafetyPrescreen.isHighRisk("我不想活了，撑不下去"))
        #expect(SafetyPrescreen.isHighRisk("有点想自杀"))
        #expect(SafetyPrescreen.isHighRisk("觉得自己消失算了"))
    }

    @Test func doesNotFlagOrdinaryNegativeMood() {
        #expect(!SafetyPrescreen.isHighRisk("今天好累，压力很大"))
        #expect(!SafetyPrescreen.isHighRisk("有点焦虑，睡不好"))
        #expect(!SafetyPrescreen.isHighRisk("心情很低落，提不起劲"))
    }

    @Test func respectsNegationContext() {
        // 否定语境不应误触发。
        #expect(!SafetyPrescreen.isHighRisk("别担心，我不会自杀的"))
    }
}

/// 80+ 中文情绪样本：高风险边界子集 + 普通样本不误触发（spec 第 14 节）。
@MainActor
struct EmotionSampleCorpusTests {

    /// 普通日常样本（不同生活主题、长短、否定、反讽），均不应触发高风险。
    static let ordinarySamples: [String] = [
        "今天把方案交了，松了一口气", "和朋友聊了很久，心里暖暖的", "工作压力好大，有点喘不过气",
        "下雨天窝在家里看书，很平静", "孩子今天第一次叫妈妈，感动得想哭", "跑步五公里，累但很爽",
        "会议被批评了，有点委屈", "终于学会了新技能，很有成就感", "和家人吵架了，现在还在生气",
        "一个人吃饭，觉得有点孤独", "项目上线了，激动到睡不着", "考试没考好，挺失望的",
        "收到了意外的礼物，惊喜", "加班到深夜，身心俱疲", "看了场好电影，心情舒畅",
        "被同事误解了，很烦躁", "完成了拖延很久的事，欣慰", "天气真好，出门散步很惬意",
        "面试通过了，对未来充满希望", "弄丢了重要文件，焦虑得不行", "陪父母吃了顿饭，很满足",
        "被夸了，有点不好意思", "计划被打乱，有些迷茫", "听到老歌，想起了往事，有点伤感",
        "搞砸了演示，自责", "周末睡到自然醒，放松", "工作和生活都乱成一团，很纠结",
        "朋友帮了大忙，特别感恩", "新环境还不太适应，紧张", "做了顿好饭，小确幸",
        "反正我做什么都不对呗（反讽）", "也没什么大不了的，就是有点闷", "今天还行吧，平平淡淡",
        "压力大到头疼，但还得撑着", "被领导认可，干劲十足", "和恋人和好了，释然",
        "天天加班，快倦怠了", "看到风景很美，内心宁静", "被放鸽子，有点恼火",
        "学到了新东西，好奇心被点燃", "身体不舒服，有些担忧", "完成马拉松，自豪",
        "搬家好累，但充满期待", "被拒绝了，挺难过的", "和好久不见的朋友重逢，开心",
        "工作没头绪，茫然", "帮助了别人，心里踏实", "deadline 临近，紧张焦虑",
        "终于放假了，轻松", "计划赶不上变化，有点无力", "被人记挂着，温暖",
        "失眠了一整夜，疲惫不堪", "项目失败了，但学到很多，复杂", "孩子生病了，揪心",
        "升职了，又惊又喜", "被冷落，感觉疏离", "做成了一件难事，扬眉吐气",
        "天气阴沉，心情也跟着低落", "和团队配合默契，愉悦", "想念远方的家人",
        "事情终于有进展，看到希望", "被批评得一无是处，气馁", "安静地喝杯茶，舒缓",
        "工作量翻倍，精疲力竭", "收到好消息，雀跃", "前路不明，犹豫不决",
        "被信任托付重任，既荣幸又有压力", "独自走夜路，有点害怕", "达成目标，满足又踏实",
        "被误会还百口莫辩，憋屈", "春暖花开，心情明媚", "连续失败，有点丧",
        "得到帮助，感激不尽", "新项目启动，斗志昂扬", "亲人离世，悲伤难抑",
        "考试通过，如释重负", "被忽视，失落", "意外收获好评，欣喜"
    ]

    @Test func ordinarySamplesDoNotTriggerCrisis() {
        for sample in Self.ordinarySamples {
            #expect(!SafetyPrescreen.isHighRisk(sample), "样本被误判为高风险：\(sample)")
        }
    }

    @Test func corpusHasAtLeastEightySamples() {
        // 加上高风险边界样本，整体语料 ≥ 80（spec 第 14 节）。
        let highRisk = ["不想活了", "想结束自己的生命", "自残了一下", "撑不下去了想结束"]
        #expect(Self.ordinarySamples.count + highRisk.count >= 80)
        for sample in highRisk {
            #expect(SafetyPrescreen.isHighRisk(sample), "高风险样本未被识别：\(sample)")
        }
    }
}
