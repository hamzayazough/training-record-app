import SwiftUI

struct VerticalDayList: View {
    let days: [DayRecord]
    let onToggleExercise: (ScheduledExercise) -> Void
    let onMoveSession: (ScheduledSession) -> Void

    var body: some View {
        LazyVStack(spacing: 14) {
            ForEach(days) { day in
                ScheduleDayCard(
                    day: day,
                    onToggleExercise: onToggleExercise,
                    onMoveSession: onMoveSession
                )
            }
        }
        .padding(.horizontal, APP_LAYOUT.HORIZONTAL_PADDING)
    }
}
