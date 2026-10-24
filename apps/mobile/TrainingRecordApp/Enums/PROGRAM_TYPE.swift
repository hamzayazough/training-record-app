import Foundation

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
}
