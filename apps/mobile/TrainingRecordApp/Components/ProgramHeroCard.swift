import SwiftUI

struct ProgramHeroCard: View {
    let type: PROGRAM_TYPE
    let subtitle: String

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            RoundedRectangle(cornerRadius: APP_LAYOUT.CARD_CORNER_RADIUS, style: .continuous)
                .fill(gradient)
                .frame(height: 160)
                .shadow(color: .black.opacity(0.12), radius: 16, y: 8)

            Image(illustrationName)
                .resizable()
                .scaledToFill()
                .opacity(0.35)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                .clipped()
                .overlay(alignment: .topTrailing) {
                    Image(systemName: iconName)
                        .font(.system(size: 64, weight: .light))
                        .foregroundStyle(.white.opacity(0.55))
                        .padding(20)
                }

            VStack(alignment: .leading, spacing: 8) {
                Text(type.title.uppercased())
                    .font(.title2.weight(.bold))
                    .foregroundStyle(.white)
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.9))
                    .lineLimit(2)
            }
            .padding(22)
        }
    }

    private var gradient: LinearGradient {
        switch type {
        case .ENDURANCE:
            return LinearGradient(
                colors: [APP_COLORS.PRIMARY_GREEN, Color(red: 0.05, green: 0.45, blue: 0.30)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .CALISTHENICS:
            return LinearGradient(
                colors: [APP_COLORS.NAVY, APP_COLORS.ACCENT_PURPLE],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }

    private var iconName: String {
        switch type {
        case .ENDURANCE: return "figure.run"
        case .CALISTHENICS: return "figure.strengthtraining.traditional"
        }
    }

    private var illustrationName: String {
        switch type {
        case .ENDURANCE: return "EnduranceIllustration"
        case .CALISTHENICS: return "CalisthenicsIllustration"
        }
    }
}
