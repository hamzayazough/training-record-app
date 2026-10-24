import Foundation

struct ProgramBlockSeed: Codable, Hashable {
    let id: String
    let name: String
    let weekStart: Int
    let weekEnd: Int
}

struct ExerciseTemplate: Codable {
    let name: String
    let prescription: String?
    let targetWeight: String?
    let setsReps: String?
    let rest: String?
    let distance: String?
    let pace: String?
    let duration: String?
    let intervals: String?
    let metrics: [String]
}

struct SessionTemplate: Codable {
    let dayNumber: Int
    let defaultWeekday: WEEKDAY
    let sessionLabel: String
    let exercises: [ExerciseTemplate]
}

struct WeekTemplate: Codable {
    let weekNumber: Int
    let sessions: [SessionTemplate]
}

struct ProgramSeed: Codable {
    let programType: PROGRAM_TYPE
    let title: String
    let totalWeeks: Int
    let defaultWeekdayByDayNumber: [String: WEEKDAY]
    let blocks: [ProgramBlockSeed]?
    let weeks: [WeekTemplate]

    var resolvedBlocks: [ProgramBlockSeed] {
        if let blocks, !blocks.isEmpty { return blocks }
        return [
            ProgramBlockSeed(
                id: "FULL_PROGRAM",
                name: "Full program",
                weekStart: 1,
                weekEnd: totalWeeks
            )
        ]
    }
}

struct PersistedProgramState: Codable {
    var programType: PROGRAM_TYPE
    var title: String
    var totalWeeks: Int
    var startDate: String
    /// blockId -> dayNumber(string) -> weekday
    var weekdayByBlock: [String: [String: WEEKDAY]]
}

struct PersistedStoreSnapshot: Codable {
    var programs: [PersistedProgramState]
    var sessions: [ScheduledSession]
}
