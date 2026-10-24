import Foundation

enum APIError: Error {
    case invalidURL
    case badResponse
    case decodingFailed
    case store(Error)
}

/// Facade over on-device `ProgramStore` (+ lightweight Atlas sync). No Nest server required.
final class TrainingAPIClient {
    static let SHARED = TrainingAPIClient()

    private let store: ProgramStore

    init(store: ProgramStore = .shared) {
        self.store = store
    }

    func fetchPrograms() async throws -> [ProgramSummary] {
        try await store.ensureReady()
        return await store.listPrograms()
    }

    func fetchCalendar(
        type: PROGRAM_TYPE,
        from: String = DayRecord.todayIso(),
        days: Int = API_CONFIG.HOME_CALENDAR_DAYS
    ) async throws -> [DayRecord] {
        try await store.ensureReady()
        return await store.getCalendar(type: type, from: from, days: days)
    }

    func fetchDetail(type: PROGRAM_TYPE) async throws -> [DayRecord] {
        let from = ScheduleDateHelpers.addDays(DayRecord.todayIso(), days: -7)
        return try await fetchCalendar(type: type, from: from, days: 29)
    }

    func completeExercise(id: String) async throws -> CompleteExerciseResponse {
        try await store.ensureReady()
        do {
            return try await store.completeExercise(id: id)
        } catch {
            throw APIError.store(error)
        }
    }

    func submitFeedback(id: String, request: FeedbackRequest) async throws -> ScheduledExercise {
        try await store.ensureReady()
        do {
            return try await store.submitFeedback(
                id: id,
                status: request.status,
                adjustments: request.adjustments
            )
        } catch {
            throw APIError.store(error)
        }
    }

    func moveSession(id: String, request: MoveSessionRequest) async throws -> ScheduledSession {
        try await store.ensureReady()
        do {
            var targetDate = request.targetDate
            if targetDate == nil, let weekdayRaw = request.targetWeekday?.uppercased(),
               let weekday = WEEKDAY(rawValue: weekdayRaw) {
                let today = DayRecord.todayIso()
                let weekStart = ScheduleDateHelpers.startOfWeekMonday(today)
                guard let monday = ScheduleDateHelpers.parseIso(weekStart) else {
                    throw ProgramStoreError.sessionNotFound
                }
                targetDate = ScheduleDateHelpers.toIsoDate(
                    ScheduleDateHelpers.dateForWeekdayInWeek(weekStartMonday: monday, weekday: weekday)
                )
            }
            guard let targetDate else { throw ProgramStoreError.sessionNotFound }
            return try await store.moveSession(id: id, targetDate: targetDate)
        } catch {
            throw APIError.store(error)
        }
    }

    func fetchRearrangeLayout(type: PROGRAM_TYPE, blockId: String? = nil) async throws -> RearrangeLayout {
        try await store.ensureReady()
        do {
            return try await store.getRearrangeLayout(type: type, blockId: blockId)
        } catch {
            throw APIError.store(error)
        }
    }

    func saveRearrange(type: PROGRAM_TYPE, request: RearrangeRequest) async throws -> RearrangeLayout {
        try await store.ensureReady()
        do {
            try await store.rearrangeSchedule(
                type: type,
                blockId: request.blockId,
                assignments: request.assignments
            )
            return try await store.getRearrangeLayout(type: type, blockId: request.blockId)
        } catch {
            throw APIError.store(error)
        }
    }
}
