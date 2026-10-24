import SwiftUI

struct ScheduleDayCard: View {
    let day: DayRecord
    let label: String

    var body: some View {
        HStack(alignment: .center, spacing: 14) {
            VStack(alignment: .leading, spacing: 2) {
                Text(day.weekday.shortLabel)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(APP_COLORS.MUTED_TEXT)
                Text(day.dayNumber)
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(APP_COLORS.NAVY)
            }

            Text(label)
                .font(.headline)
                .foregroundStyle(label.isEmpty ? APP_COLORS.MUTED_TEXT : APP_COLORS.NAVY)
                .lineLimit(2)
                .frame(maxWidth: .infinity, alignment: .leading)

            StatusDot(status: day.displayStatus)
            if day.hasTraining {
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(APP_COLORS.MUTED_TEXT)
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
        .opacity(label.isEmpty && !day.hasTraining ? 0.7 : 1)
    }

    private var cardBackground: Color {
        switch day.displayStatus {
        case .GOOD: return APP_COLORS.STATUS_GOOD.opacity(0.12)
        case .SO_SO: return APP_COLORS.STATUS_SO_SO.opacity(0.12)
        case .BAD: return APP_COLORS.STATUS_BAD.opacity(0.12)
        case .PENDING where day.isToday: return APP_COLORS.PRIMARY_GREEN.opacity(0.08)
        case .REST where !label.isEmpty: return APP_COLORS.STATUS_REST.opacity(0.55)
        default: return APP_COLORS.SURFACE
        }
    }

    private var borderColor: Color {
        day.isToday ? APP_COLORS.PRIMARY_GREEN.opacity(0.55) : Color.black.opacity(0.04)
    }
}
