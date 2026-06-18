import SwiftUI

struct UniverseAccessibleList: View {
    var month: MonthlyUniverseSummary
    var onSelect: (UniverseDaySummary) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("有记录的日子", systemImage: "calendar.day.timeline.left")
                .font(.headline)
                .foregroundStyle(.white)

            ForEach(month.days) { day in
                Button {
                    onSelect(day)
                } label: {
                    HStack(spacing: 14) {
                        VStack(spacing: 2) {
                            Text(day.date, format: .dateTime.day())
                                .font(.title3.weight(.bold))
                            Text(day.date, format: .dateTime.weekday(.abbreviated))
                                .font(.caption)
                        }
                        .frame(width: 48)
                        .foregroundStyle(.white)

                        VStack(alignment: .leading, spacing: 4) {
                            Text(day.cocktailName)
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(.white)
                            Text("\(day.weatherType) · \(day.keywords.prefix(2).joined(separator: " · "))")
                                .font(.caption)
                                .foregroundStyle(.white.opacity(0.68))
                                .lineLimit(2)
                        }

                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundStyle(.white.opacity(0.5))
                    }
                    .frame(minHeight: 52)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)

                if day.id != month.days.last?.id {
                    Divider().overlay(.white.opacity(0.12))
                }
            }
        }
        .padding(18)
        .background(.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(.white.opacity(0.12), lineWidth: 1)
        }
    }
}
