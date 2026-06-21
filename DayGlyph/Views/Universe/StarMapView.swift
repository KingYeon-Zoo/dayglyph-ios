import SwiftUI

/// 纯 SwiftUI 玻璃拟态深空星图，取代原 RealityKit `UniverseRealityView`。
///
/// 每条记录是一颗带常驻日期数字的「记录星」，按 `StarMapLayout` 确定性散布。
/// 颜色编码主导情绪、大小编码能量。背景为深空渐变 + 星云雾斑 + 背景星尘。
/// 全程纯状态驱动渲染，月份切换走交叉淡入淡出，不存在初始化空帧，不会黑屏。
struct StarMapView: View {
    var month: MonthlyUniverseSummary
    var selectedDate: Date?
    var reduceMotion: Bool
    var onSelectDate: (Date) -> Void

    private var visual: MonthlyPlanetVisual { month.visual }

    private var placements: [StarPlacement] {
        StarMapLayout.placements(dates: month.days.map(\.date), seed: visual.seed)
    }

    private var today: Date { Calendar.current.startOfDay(for: .now) }

    var body: some View {
        GeometryReader { proxy in
            let size = proxy.size
            ZStack {
                StarFieldBackground(visual: visual)

                ForEach(placements, id: \.date) { placement in
                    if let day = day(for: placement.date) {
                        RecordStar(
                            day: day,
                            isSelected: isSelected(placement.date),
                            isToday: Calendar.current.isDate(placement.date, inSameDayAs: today),
                            reduceMotion: reduceMotion
                        )
                        .position(
                            x: placement.unitPosition.x * size.width,
                            y: placement.unitPosition.y * size.height
                        )
                        .onTapGesture { onSelectDate(placement.date) }
                    }
                }
            }
            .frame(width: size.width, height: size.height)
        }
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .transition(.opacity)
        .id(month.id)
    }

    private func day(for date: Date) -> UniverseDaySummary? {
        month.days.first { Calendar.current.isDate($0.date, inSameDayAs: date) }
    }

    private func isSelected(_ date: Date) -> Bool {
        guard let selectedDate else { return false }
        return Calendar.current.isDate(selectedDate, inSameDayAs: date)
    }
}
