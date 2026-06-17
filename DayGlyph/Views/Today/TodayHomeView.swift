import SwiftData
import SwiftUI

struct TodayHomeView: View {
    var body: some View {
        TodayView()
    }
}

#Preview {
    TodayHomeView()
        .modelContainer(for: DayEntry.self, inMemory: true)
}
