import SwiftUI

struct VerticalDayList: View {
    let days: [DayRecord]
    let labelForDay: (DayRecord) -> String
    let onAppearDay: (DayRecord) -> Void

    var body: some View {
        VStack(spacing: 14) {
            ForEach(days) { day in
                Group {
                    if day.hasTraining {
                        NavigationLink(value: PROGRAM_ROUTE.dayDetail(day.id)) {
                            ScheduleDayCard(day: day, label: labelForDay(day))
                        }
                        .buttonStyle(.plain)
                    } else {
                        ScheduleDayCard(day: day, label: labelForDay(day))
                    }
                }
                .id(day.id)
                .onAppear { onAppearDay(day) }
            }
        }
        .padding(.horizontal, APP_LAYOUT.HORIZONTAL_PADDING)
    }
}
