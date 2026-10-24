import SwiftUI

enum PROGRAM_TYPE: String, Codable, CaseIterable, Identifiable {
    case ENDURANCE
    case CALISTHENICS

    var id: String { rawValue }

    var title: String {
        switch self {
        case .ENDURANCE: return "Endurance"
        case .CALISTHENICS: return "Calisthenics"
        }
    }

    var iconName: String {
        switch self {
        case .ENDURANCE: return "figure.run"
        case .CALISTHENICS: return "figure.strengthtraining.traditional"
        }
    }

    var heroGradient: LinearGradient {
        switch self {
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
}
