import Foundation

enum WEEKDAY: String, Codable, CaseIterable {
    case MONDAY
    case TUESDAY
    case WEDNESDAY
    case THURSDAY
    case FRIDAY
    case SATURDAY
    case SUNDAY

    var shortLabel: String {
        String(rawValue.prefix(3)).capitalized
    }
}
