import SwiftUI

enum PERFORMANCE_STATUS: String, Codable {
    case GOOD
    case SO_SO
    case BAD
    case PENDING
    case REST

    var color: Color {
        switch self {
        case .GOOD: return APP_COLORS.STATUS_GOOD
        case .SO_SO: return APP_COLORS.STATUS_SO_SO
        case .BAD: return APP_COLORS.STATUS_BAD
        case .PENDING: return APP_COLORS.STATUS_PENDING
        case .REST: return APP_COLORS.STATUS_REST
        }
    }
}
