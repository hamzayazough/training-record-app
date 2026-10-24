import SwiftUI

struct DayCard: View {
    let day: DayRecord
    var isCompact: Bool = true
    var isHighlighted: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(day.weekday.shortLabel)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(isHighlighted ? .white.opacity(0.85) : APP_COLORS.MUTED_TEXT)
                Spacer()
                StatusDot(status: day.displayStatus, size: 8)
            }
            Text(dayLabel)
                .font(.system(size: isCompact ? 22 : 28, weight: .bold))
                .foregroundStyle(isHighlighted ? .white : APP_COLORS.NAVY)
            Text(day.summary)
                .font(.caption)
                .foregroundStyle(isHighlighted ? .white.opacity(0.9) : APP_COLORS.MUTED_TEXT)
                .lineLimit(isCompact ? 2 : 4)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(16)
        .frame(width: isCompact ? 132 : nil, alignment: .leading)
        .frame(maxWidth: isCompact ? nil : .infinity, alignment: .leading)
        .background(cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: APP_LAYOUT.CORNER_RADIUS, style: .continuous))
        .shadow(color: .black.opacity(0.06), radius: APP_LAYOUT.CARD_SHADOW_RADIUS, y: APP_LAYOUT.CARD_SHADOW_Y)
        .overlay(
            RoundedRectangle(cornerRadius: APP_LAYOUT.CORNER_RADIUS, style: .continuous)
                .stroke(borderColor, lineWidth: isHighlighted ? 0 : 1)
        )
    }

    private var dayLabel: String {
        let parts = day.date.split(separator: "-")
        guard parts.count == 3 else { return day.date }
        return String(parts[2])
    }

    private var cardBackground: Color {
        if isHighlighted { return APP_COLORS.PRIMARY_GREEN }
        switch day.displayStatus {
        case .GOOD: return APP_COLORS.STATUS_GOOD.opacity(0.12)
        case .SO_SO: return APP_COLORS.STATUS_SO_SO.opacity(0.12)
        case .BAD: return APP_COLORS.STATUS_BAD.opacity(0.12)
        default: return APP_COLORS.SURFACE
        }
    }

    private var borderColor: Color {
        Color.black.opacity(0.04)
    }
}
