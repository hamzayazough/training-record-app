import SwiftUI

struct ScheduleDayCard: View {
    let day: DayRecord
    let onToggleExercise: (ScheduledExercise) -> Void
    let onMoveSession: (ScheduledSession) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            header
            ForEach(day.sessions) { session in
                if day.sessions.count > 1 {
                    Text(session.sessionLabel)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(APP_COLORS.MUTED_TEXT)
                }
                ForEach(session.exercises) { exercise in
                    ExerciseRow(
                        exercise: exercise,
                        isInteractive: day.isToday,
                        isCompact: true,
                        onToggle: { onToggleExercise(exercise) }
                    )
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: APP_LAYOUT.CORNER_RADIUS, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: APP_LAYOUT.CORNER_RADIUS, style: .continuous)
                .stroke(borderColor, lineWidth: day.isToday ? 2 : 1)
        )
        .shadow(color: .black.opacity(0.06), radius: APP_LAYOUT.CARD_SHADOW_RADIUS, y: APP_LAYOUT.CARD_SHADOW_Y)
    }

    private var header: some View {
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: 2) {
                Text(day.weekday.shortLabel)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(APP_COLORS.MUTED_TEXT)
                Text(dayNumber)
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(APP_COLORS.NAVY)
            }
            Spacer()
            if day.isToday, let session = day.sessions.first {
                Button("Move") {
                    onMoveSession(session)
                }
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(APP_COLORS.ACCENT_ORANGE)
            }
            StatusDot(status: day.displayStatus)
        }
    }

    private var dayNumber: String {
        let parts = day.date.split(separator: "-")
        guard parts.count == 3 else { return day.date }
        return String(parts[2])
    }

    private var cardBackground: Color {
        switch day.displayStatus {
        case .GOOD: return APP_COLORS.STATUS_GOOD.opacity(0.12)
        case .SO_SO: return APP_COLORS.STATUS_SO_SO.opacity(0.12)
        case .BAD: return APP_COLORS.STATUS_BAD.opacity(0.12)
        case .PENDING where day.isToday: return APP_COLORS.PRIMARY_GREEN.opacity(0.08)
        default: return APP_COLORS.SURFACE
        }
    }

    private var borderColor: Color {
        day.isToday ? APP_COLORS.PRIMARY_GREEN.opacity(0.55) : Color.black.opacity(0.04)
    }
}
