import SwiftUI

struct HorizontalDayStrip: View {
    let days: [DayRecord]

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(days) { day in
                    DayCard(day: day, isCompact: true, isHighlighted: day.isToday)
                }
            }
            .padding(.horizontal, APP_LAYOUT.HORIZONTAL_PADDING)
            .padding(.vertical, 4)
        }
    }
}
