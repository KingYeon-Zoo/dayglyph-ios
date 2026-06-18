import Foundation

@MainActor
enum LocalDataExporter {
    struct EntryPayload: Codable {
        var date: Date
        var text: String
        var recipeName: String
        var weather: String
        var keywords: [String]
        var isDemo: Bool
    }

    static func export(entries: [DayEntry]) throws -> URL {
        let payload = entries.sorted { $0.date < $1.date }.map {
            EntryPayload(
                date: $0.date,
                text: $0.text,
                recipeName: $0.emotionRecipe.name,
                weather: $0.moodWeather.type,
                keywords: $0.keywords,
                isDemo: $0.isDemo
            )
        }
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("DayGlyph-本地记录.json")
        try encoder.encode(payload).write(to: url, options: .atomic)
        return url
    }
}
