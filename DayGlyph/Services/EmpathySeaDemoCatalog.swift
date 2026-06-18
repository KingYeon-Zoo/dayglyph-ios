import Foundation

nonisolated struct EmpathySeaPost: Equatable, Identifiable {
    var id: String
    var text: String
    var mood: String
    var responses: [String]
}

nonisolated enum EmpathySeaDemoCatalog {
    static let posts: [EmpathySeaPost] = [
        EmpathySeaPost(
            id: "sea-quiet-after-work",
            text: "忙完以后突然安静下来，才发现自己其实已经累了很久。",
            mood: "柔和的阴天",
            responses: ["我也有过类似的时刻", "谢谢你写下这些", "愿你今天轻一点"]
        ),
        EmpathySeaPost(
            id: "sea-small-relief",
            text: "事情没有完全解决，但今天终于有一个小地方松动了。",
            mood: "雨后的微风",
            responses: ["这一步值得被看见", "谢谢你分享这点变化", "愿松动继续发生"]
        ),
        EmpathySeaPost(
            id: "sea-hard-to-name",
            text: "说不上是难过还是担心，只知道脑子里一直很吵。",
            mood: "起伏的阵雨",
            responses: ["不用急着把它说清楚", "我认真读到了", "愿你先有一点安静"]
        )
    ]

    static func contactWarnings(in text: String) -> [String] {
        var warnings: [String] = []
        if text.range(
            of: #"[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}"#,
            options: .regularExpression
        ) != nil {
            warnings.append("邮箱地址")
        }
        if text.range(
            of: #"(?<!\d)1[3-9]\d{9}(?!\d)"#,
            options: .regularExpression
        ) != nil {
            warnings.append("电话号码")
        }
        return warnings
    }

    static func isReported(postID: String, reportedIDs: Set<String>) -> Bool {
        reportedIDs.contains(postID)
    }
}
