import SwiftUI

struct VerticalDayList: View {
    let days: [DayRecord]
    let onSelectSession: (ScheduledSession) -> Void

    var body: some View {
        LazyVStack(spacing: 14) {
            ForEach(days) { day in
                VStack(alignment: .leading, spacing: 12) {
                    DayCard(day: day, isCompact: false, isHighlighted: day.isToday)
                    ForEach(day.sessions) { session in
                        Button {
                            onSelectSession(session)
                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(session.sessionLabel)
                                        .font(.subheadline.weight(.semibold))
                                        .foregroundStyle(APP_COLORS.NAVY)
                                    Text("Week \(session.weekNumber)")
                                        .font(.caption)
                                        .foregroundStyle(APP_COLORS.MUTED_TEXT)
                                }
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .foregroundStyle(APP_COLORS.MUTED_TEXT)
                            }
                            .padding(14)
                            .background(APP_COLORS.SURFACE)
                            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .padding(.horizontal, APP_LAYOUT.HORIZONTAL_PADDING)
    }
}
