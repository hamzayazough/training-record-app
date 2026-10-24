import SwiftUI

struct DayStatusBadge: View {
    let badge: DAY_CARD_BADGE

    var body: some View {
        Text(badge.title)
            .font(.caption2.weight(.bold))
            .foregroundStyle(.white)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(badge.color)
            .clipShape(
                .rect(
                    topLeadingRadius: APP_LAYOUT.CORNER_RADIUS,
                    bottomLeadingRadius: 0,
                    bottomTrailingRadius: 10,
                    topTrailingRadius: 0
                )
            )
    }
}
