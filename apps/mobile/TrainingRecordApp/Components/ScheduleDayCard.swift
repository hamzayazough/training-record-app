import SwiftUI

struct ScheduleDayCard: View {
    let day: DayRecord
    let label: String

    private var isTodayPending: Bool {
        day.isToday && day.cardBadge == nil
    }

    private var todayAccent: Color {
        isTodayPending ? APP_COLORS.TODAY_BLUE : APP_COLORS.PRIMARY_GREEN
    }

    var body: some View {
        HStack(alignment: .center, spacing: day.isToday ? 16 : 14) {
            VStack(alignment: .leading, spacing: day.isToday ? 4 : 2) {
                HStack(spacing: 6) {
                    Text(day.weekday.shortLabel)
                        .font((day.isToday ? Font.subheadline : Font.caption).weight(.semibold))
                        .foregroundStyle(day.isToday ? todayAccent : APP_COLORS.MUTED_TEXT)
                    if day.isToday {
                        Text("Today")
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(todayAccent)
                            .clipShape(Capsule())
                    }
                }
                Text(day.dayNumber)
                    .font(.system(size: day.isToday ? 36 : 28, weight: .bold))
                    .foregroundStyle(APP_COLORS.NAVY)
            }

            Text(label)
                .font(day.isToday ? .title3.weight(.bold) : .headline)
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
        .padding(day.isToday ? 20 : 16)
        .padding(.top, day.cardBadge == nil ? 0 : 10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: APP_LAYOUT.CORNER_RADIUS, style: .continuous))
        .overlay(alignment: .topLeading) {
            if let badge = day.cardBadge {
                DayStatusBadge(badge: badge)
            }
        }
        .overlay(
            RoundedRectangle(cornerRadius: APP_LAYOUT.CORNER_RADIUS, style: .continuous)
                .stroke(borderColor, lineWidth: borderWidth)
        )
        .shadow(
            color: .black.opacity(day.isToday ? 0.12 : 0.06),
            radius: day.isToday ? 16 : APP_LAYOUT.CARD_SHADOW_RADIUS,
            y: day.isToday ? 8 : APP_LAYOUT.CARD_SHADOW_Y
        )
        .opacity(label.isEmpty && !day.hasTraining && !day.isToday ? 0.7 : 1)
        .scaleEffect(day.isToday ? 1.02 : 1)
    }

    private var cardBackground: Color {
        if isTodayPending {
            return APP_COLORS.TODAY_BLUE.opacity(0.14)
        }
        if day.isToday {
            return todayAccent.opacity(0.16)
        }
        if day.cardBadge == .completed {
            return APP_COLORS.STATUS_GOOD.opacity(0.12)
        }
        switch day.displayStatus {
        case .GOOD: return APP_COLORS.STATUS_GOOD.opacity(0.12)
        case .SO_SO: return APP_COLORS.STATUS_SO_SO.opacity(0.12)
        case .BAD: return APP_COLORS.STATUS_BAD.opacity(0.12)
        case .REST where !label.isEmpty: return APP_COLORS.STATUS_REST.opacity(0.55)
        default: return APP_COLORS.SURFACE
        }
    }

    private var borderColor: Color {
        if isTodayPending {
            return .clear
        }
        return Color.black.opacity(0.04)
    }

    private var borderWidth: CGFloat {
        isTodayPending ? 0 : 1
    }
}
