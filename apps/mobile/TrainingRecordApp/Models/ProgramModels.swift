import Foundation

struct ProgramSummary: Codable, Identifiable {
    let programType: PROGRAM_TYPE
    let title: String
    let totalWeeks: Int
    let currentWeek: Int
    let startDate: String

    var id: String { programType.rawValue }
}

struct ExerciseAdjustment: Codable, Equatable {
    var weight: String?
    var reps: String?
    var sets: String?
    var distance: String?
    var pace: String?
    var duration: String?
    var notes: String?
}

struct ScheduledExercise: Codable, Identifiable, Equatable {
    let id: String
    let name: String
    let prescription: String
    let targetWeight: String?
    let setsReps: String?
    let rest: String?
    let metrics: [String]
    var completed: Bool
    var status: PERFORMANCE_STATUS
    var adjustments: ExerciseAdjustment?
}

struct ScheduledSession: Codable, Identifiable, Equatable {
    let id: String
    let programType: PROGRAM_TYPE
    let weekNumber: Int
    let dayNumber: Int
    let sessionLabel: String
    var date: String
    var weekday: WEEKDAY
    var exercises: [ScheduledExercise]
}

struct DayRecord: Codable, Identifiable, Equatable {
    let date: String
    let weekday: WEEKDAY
    let sessions: [ScheduledSession]
    let overallStatus: PERFORMANCE_STATUS
    let summary: String

    var id: String { date }

    var isToday: Bool {
        date == Self.todayIso()
    }

    var isPast: Bool {
        date < Self.todayIso()
    }

    var allExercises: [ScheduledExercise] {
        sessions.flatMap(\.exercises)
    }

    /// Past incomplete days surface as BAD; otherwise derive from exercise feedback.
    var displayStatus: PERFORMANCE_STATUS {
        let exercises = allExercises
        if exercises.isEmpty { return .REST }
        if isPast && exercises.contains(where: { !$0.completed || $0.status == .PENDING }) {
            return .BAD
        }
        let actionable = exercises.map(\.status).filter { $0 != .PENDING }
        if actionable.isEmpty { return .PENDING }
        if actionable.contains(.BAD) { return .BAD }
        if actionable.contains(.SO_SO) { return .SO_SO }
        if actionable.allSatisfy({ $0 == .GOOD }) { return .GOOD }
        return overallStatus
    }

    static func todayIso() -> String {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: Date())
    }
}

struct CompleteExerciseResponse: Codable {
    let exercise: ScheduledExercise
    let promptFeedback: Bool
    let message: String
}

struct FeedbackRequest: Codable {
    let status: PERFORMANCE_STATUS
    let adjustments: ExerciseAdjustment?
}

struct MoveSessionRequest: Codable {
    let targetDate: String?
    let targetWeekday: String?
}
