import SwiftUI

struct EmotionStatisticsView: View {
    var entries: [DayEntry]

    var body: some View {
        UniverseTrendsView(entries: entries, initialDate: .now)
            .navigationTitle("情绪统计")
    }
}
