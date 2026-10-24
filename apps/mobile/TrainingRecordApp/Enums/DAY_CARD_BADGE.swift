import SwiftUI

enum DAY_CARD_BADGE {
    case completed
    case missed

    var title: String {
        switch self {
        case .completed: return "Completed"
        case .missed: return "Missed"
        }
    }

    var color: Color {
        switch self {
        case .completed: return APP_COLORS.STATUS_GOOD
        case .missed: return APP_COLORS.STATUS_BAD
        }
    }
}
