import Foundation

@MainActor
final class HomeViewModel: ObservableObject {
    @Published var programs: [ProgramSummary] = []
    @Published var calendarDays: [DayRecord] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private var enduranceDays: [DayRecord] = []
    private var calisthenicsDays: [DayRecord] = []
    private let api: TrainingAPIClient

    init(api: TrainingAPIClient = .SHARED) {
        self.api = api
    }

    func load() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            async let programsTask = api.fetchPrograms()
            async let calendarTask = api.fetchCalendar(type: .CALISTHENICS, days: API_CONFIG.HOME_CALENDAR_DAYS)
            async let enduranceCalendar = api.fetchCalendar(type: .ENDURANCE, days: API_CONFIG.HOME_CALENDAR_DAYS)
            let (loadedPrograms, caliDays, enduDays) = try await (programsTask, calendarTask, enduranceCalendar)
            programs = loadedPrograms
            calisthenicsDays = caliDays
            enduranceDays = enduDays
            calendarDays = mergeHomeCalendar(caliDays: caliDays, enduDays: enduDays)
        } catch {
            errorMessage = "Could not reach the training API. Is the Nest server running?"
        }
    }

    func day(forId dayId: String) -> DayRecord? {
        calendarDays.first(where: { $0.id == dayId })
    }

    func subtitle(for type: PROGRAM_TYPE) -> String {
        guard let program = programs.first(where: { $0.programType == type }) else {
            return type == .ENDURANCE ? "Running & bike plan" : "Weighted strength plan"
        }
        return "Week \(program.currentWeek) of \(program.totalWeeks)"
    }

    func todayTrainingLabel(for type: PROGRAM_TYPE) -> String? {
        guard let day = todayDay(for: type), !day.sessions.isEmpty else { return nil }
        let names = day.sessions.map { Self.titleCased($0.sessionLabel) }
        return "Today: \(names.joined(separator: ", "))"
    }

    func todayTrainingCompleted(for type: PROGRAM_TYPE) -> Bool {
        guard let day = todayDay(for: type), !day.sessions.isEmpty else { return false }
        let exercises = day.sessions.flatMap(\.exercises)
        return !exercises.isEmpty && exercises.allSatisfy(\.completed)
    }

    private func todayDay(for type: PROGRAM_TYPE) -> DayRecord? {
        let days = type == .ENDURANCE ? enduranceDays : calisthenicsDays
        return days.first(where: \.isToday)
    }

    private func mergeHomeCalendar(caliDays: [DayRecord], enduDays: [DayRecord]) -> [DayRecord] {
        let enduByDate = Dictionary(uniqueKeysWithValues: enduDays.map { ($0.date, $0) })
        return caliDays.map { cali in
            let endu = enduByDate[cali.date]
            let sessions = cali.sessions + (endu?.sessions ?? [])
            let summaries = [cali.summary, endu?.summary]
                .compactMap { $0 }
                .filter { $0 != "Rest" }
            let summary = summaries.isEmpty ? "Rest" : summaries.joined(separator: " · ")
            let statusCandidates = [cali.overallStatus, endu?.overallStatus].compactMap { $0 }
            let overall: PERFORMANCE_STATUS
            if statusCandidates.contains(.BAD) {
                overall = .BAD
            } else if statusCandidates.contains(.SO_SO) {
                overall = .SO_SO
            } else if statusCandidates.contains(.GOOD) {
                overall = .GOOD
            } else if sessions.isEmpty {
                overall = .REST
            } else {
                overall = .PENDING
            }
            return DayRecord(
                date: cali.date,
                weekday: cali.weekday,
                sessions: sessions,
                overallStatus: overall,
                summary: summary
            )
        }
    }

    private static func titleCased(_ raw: String) -> String {
        raw
            .lowercased()
            .split(separator: " ")
            .map { $0.prefix(1).uppercased() + $0.dropFirst() }
            .joined(separator: " ")
    }
}
