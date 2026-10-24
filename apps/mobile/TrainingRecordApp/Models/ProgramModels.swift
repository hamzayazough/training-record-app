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
    let distance: String?
    let pace: String?
    let duration: String?
    let intervals: String?
    let metrics: [String]
    var completed: Bool
    var status: PERFORMANCE_STATUS
    var adjustments: ExerciseAdjustment?

    var hasStructuredTargets: Bool {
        !detailLines.isEmpty
    }

    var detailLines: [(label: String, value: String)] {
        var lines: [(String, String)] = []
        if let distance, !distance.isEmpty {
            lines.append(("Distance", distance))
        }
        if let pace, !pace.isEmpty {
            lines.append(("Pace", pace))
        }
        if let duration, !duration.isEmpty {
            lines.append(("Duration", duration))
        }
        if let intervals, !intervals.isEmpty {
            lines.append(("Intervals", intervals))
        }
        if let targetWeight, !targetWeight.isEmpty {
            lines.append(("Weight", targetWeight))
        }
        if let setsReps, !setsReps.isEmpty, intervals == nil || intervals?.isEmpty == true {
            lines.append(("Sets", setsReps))
        }
        if let rest, !rest.isEmpty {
            lines.append(("Rest", rest))
        }
        return lines
    }

    var fallbackPrescription: String? {
        guard !hasStructuredTargets else { return nil }
        let text = prescription.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty, text != name else { return nil }
        return text
    }
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

    var shortTrainingLabel: String {
        switch programType {
        case .CALISTHENICS:
            return Self.titleCasedLabel(sessionLabel)
        case .ENDURANCE:
            let labels = exercises.map(\.name).filter {
                !["Strength A", "Strength B"].contains($0)
            }
            if !labels.isEmpty {
                return labels.joined(separator: " · ")
            }
            return sessionLabel
        }
    }

    private static func titleCasedLabel(_ raw: String) -> String {
        raw
            .lowercased()
            .split(separator: " ")
            .map { $0.prefix(1).uppercased() + $0.dropFirst() }
            .joined(separator: " ")
    }
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

    var shortTrainingLabel: String {
        let labels = sessions.map(\.shortTrainingLabel)
        return labels.isEmpty ? "Rest" : labels.joined(separator: " · ")
    }

    var hasTraining: Bool {
        !sessions.isEmpty
    }

    var dayTitle: String {
        "\(weekday.shortLabel) \(dayNumber)"
    }

    var dayNumber: String {
        let parts = date.split(separator: "-")
        guard parts.count == 3 else { return date }
        return String(parts[2])
    }

    var weekNumber: Int? {
        sessions.first?.weekNumber
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

struct RearrangeTraining: Codable, Identifiable, Hashable {
    let dayNumber: Int
    let label: String
    var currentWeekday: WEEKDAY

    var id: Int { dayNumber }
}

struct RearrangeWeekDay: Codable, Identifiable, Hashable {
    let date: String
    let weekday: WEEKDAY
    let shortLabel: String

    var id: String { date }
}

struct RearrangeLayout: Codable {
    let trainings: [RearrangeTraining]
    let weekDays: [RearrangeWeekDay]
}

struct RearrangeAssignment: Codable {
    let dayNumber: Int
    let weekday: WEEKDAY
}

struct RearrangeRequest: Codable {
    let assignments: [RearrangeAssignment]
}
