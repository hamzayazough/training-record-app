import SwiftUI

struct ProgramHeroCard: View {
    let type: PROGRAM_TYPE
    let subtitle: String
    var todayLabel: String? = nil
    var todayCompleted: Bool = false

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            type.heroGradient

            Image(systemName: type.iconName)
                .font(.system(size: 64, weight: .light))
                .foregroundStyle(.white.opacity(0.55))
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                .padding(20)

            VStack(alignment: .leading, spacing: 8) {
                Text(type.title.uppercased())
                    .font(.title2.weight(.bold))
                    .foregroundStyle(.white)
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.9))
                    .lineLimit(2)

                if let todayLabel {
                    HStack(spacing: 6) {
                        Image(systemName: todayCompleted ? "checkmark.circle.fill" : "circle")
                            .font(.caption.weight(.semibold))
                        Text(todayLabel)
                            .font(.caption.weight(.semibold))
                            .lineLimit(2)
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color.white.opacity(0.18))
                    .clipShape(Capsule())
                }
            }
            .padding(22)
        }
        .frame(height: 160)
        .frame(maxWidth: .infinity, alignment: .leading)
        .clipShape(RoundedRectangle(cornerRadius: APP_LAYOUT.CARD_CORNER_RADIUS, style: .continuous))
        .shadow(color: .black.opacity(0.12), radius: 16, y: 8)
    }
}
