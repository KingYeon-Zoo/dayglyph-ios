import Foundation
import SwiftData

enum DayEntryStore {
    static func saveEntry(
        text: String,
        date: Date = .now,
        analysis: EmotionAnalysis,
        context: ModelContext,
        calendar: Calendar = .current,
        isDemo: Bool = false
    ) throws -> DayEntry {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            throw DayEntryStoreError.emptyText
        }

        let startOfDay = calendar.startOfDay(for: date)
        let descriptor = FetchDescriptor<DayEntry>(
            predicate: #Predicate { $0.date == startOfDay }
        )
        let seed = GlyphSignature.seed(for: trimmed, date: startOfDay, calendar: calendar)

        if let existing = try context.fetch(descriptor).first {
            existing.update(text: trimmed, analysis: analysis, glyphSeed: seed, date: .now)
            existing.isDemo = isDemo
            try context.save()
            return existing
        }

        let entry = DayEntry(
            date: startOfDay,
            text: trimmed,
            analysis: analysis,
            glyphSeed: seed,
            isDemo: isDemo
        )
        context.insert(entry)
        try context.save()
        return entry
    }
}

enum DayEntryStoreError: LocalizedError, Equatable {
    case emptyText

    var errorDescription: String? {
        switch self {
        case .emptyText: "记录内容不能为空。"
        }
    }
}
