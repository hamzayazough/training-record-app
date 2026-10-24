import SwiftUI

struct ProgramSectionHeader: View {
    let type: PROGRAM_TYPE
    let sessions: [ScheduledSession]

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: type.iconName)
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 40, height: 40)
                .background(Color.white.opacity(0.18))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text(type.title)
                    .font(.headline.weight(.bold))
                    .foregroundStyle(.white)
                if !subtitle.isEmpty {
                    Text(subtitle)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.85))
                        .lineLimit(2)
                }
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(type.heroGradient)
        .clipShape(RoundedRectangle(cornerRadius: APP_LAYOUT.CORNER_RADIUS, style: .continuous))
        .shadow(color: .black.opacity(0.10), radius: 10, y: 4)
    }

    private var subtitle: String {
        sessions
            .map { Self.titleCased($0.sessionLabel) }
            .joined(separator: ", ")
    }

    private static func titleCased(_ raw: String) -> String {
        raw
            .lowercased()
            .split(separator: " ")
            .map { $0.prefix(1).uppercased() + $0.dropFirst() }
            .joined(separator: " ")
    }
}
