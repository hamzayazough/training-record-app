import Foundation

enum ScheduleDateHelpers {
    private static let isoFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone.current
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()

    static func toIsoDate(_ date: Date) -> String {
        isoFormatter.string(from: Calendar.current.startOfDay(for: date))
    }

    static func parseIso(_ iso: String) -> Date? {
        isoFormatter.date(from: iso)
    }

    static func addDays(_ iso: String, days: Int) -> String {
        guard let date = parseIso(iso) else { return iso }
        let next = Calendar.current.date(byAdding: .day, value: days, to: date) ?? date
        return toIsoDate(next)
    }

    static func startOfWeekMonday(_ iso: String) -> String {
        guard let date = parseIso(iso) else { return iso }
        var calendar = Calendar(identifier: .gregorian)
        calendar.firstWeekday = 2
        let weekday = calendar.component(.weekday, from: date)
        let daysFromMonday = (weekday + 5) % 7
        let monday = calendar.date(byAdding: .day, value: -daysFromMonday, to: date) ?? date
        return toIsoDate(monday)
    }

    static func weekdayIndex(_ weekday: WEEKDAY) -> Int {
        switch weekday {
        case .SUNDAY: return 0
        case .MONDAY: return 1
        case .TUESDAY: return 2
        case .WEDNESDAY: return 3
        case .THURSDAY: return 4
        case .FRIDAY: return 5
        case .SATURDAY: return 6
        }
    }

    static func weekdayFromDate(_ date: Date) -> WEEKDAY {
        switch Calendar.current.component(.weekday, from: date) {
        case 1: return .SUNDAY
        case 2: return .MONDAY
        case 3: return .TUESDAY
        case 4: return .WEDNESDAY
        case 5: return .THURSDAY
        case 6: return .FRIDAY
        default: return .SATURDAY
        }
    }

    static func dateForWeekdayInWeek(weekStartMonday: Date, weekday: WEEKDAY) -> Date {
        let target = weekdayIndex(weekday)
        var offset = target - 1
        if offset < 0 { offset += 7 }
        return Calendar.current.date(byAdding: .day, value: offset, to: weekStartMonday) ?? weekStartMonday
    }

    static func shortWeekdayLabel(_ weekday: WEEKDAY) -> String {
        let raw = weekday.rawValue
        return String(raw.prefix(1)) + raw.dropFirst().prefix(2).lowercased()
    }

    static func trainingLabel(_ sessionLabel: String) -> String {
        sessionLabel
            .lowercased()
            .split(separator: " ")
            .map { $0.prefix(1).uppercased() + $0.dropFirst() }
            .joined(separator: " ")
    }
}
