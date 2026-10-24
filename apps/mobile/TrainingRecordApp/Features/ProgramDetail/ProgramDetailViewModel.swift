import Foundation

@MainActor
final class ProgramDetailViewModel: ObservableObject {
    @Published var days: [DayRecord] = []
    @Published var feedbackExercise: ScheduledExercise?
    @Published var moveSessionTarget: ScheduledSession?
    @Published var errorMessage: String?
    @Published var isLoading = false
    @Published var isLoadingPast = false
    @Published var isLoadingFuture = false

    let programType: PROGRAM_TYPE
    private let api: TrainingAPIClient
    private(set) var programStartDate: String?
    private(set) var programEndDate: String?
    private var didScrollToFocus = false
    private var pagingEnabled = false
    private var awaitingPastScrollAway = false
    private var awaitingFutureScrollAway = false

    init(programType: PROGRAM_TYPE, api: TrainingAPIClient = .SHARED) {
        self.programType = programType
        self.api = api
    }

    var focusDayId: String? {
        if let today = days.first(where: \.isToday) {
            return today.id
        }
        let todayIso = DayRecord.todayIso()
        return days.first(where: { $0.date >= todayIso })?.id ?? days.last?.id
    }

    func displayLabel(for day: DayRecord) -> String {
        if day.hasTraining {
            return day.shortTrainingLabel
        }
        if isWithinProgram(day.date) {
            return "Rest"
        }
        return ""
    }

    func isWithinProgram(_ date: String) -> Bool {
        guard let start = programStartDate, let end = programEndDate else {
            return false
        }
        return date >= start && date <= end
    }

    func load() async {
        isLoading = true
        errorMessage = nil
        pagingEnabled = false
        defer { isLoading = false }
        do {
            let programs = try await api.fetchPrograms()
            if let summary = programs.first(where: { $0.programType == programType }) {
                programStartDate = Self.startOfWeekMonday(summary.startDate)
                programEndDate = Self.addDays(programStartDate!, days: summary.totalWeeks * 7 - 1)
            }
            let from = Self.addDays(DayRecord.todayIso(), days: -CALENDAR_PAGING.INITIAL_PAST_DAYS)
            days = try await api.fetchCalendar(
                type: programType,
                from: from,
                days: CALENDAR_PAGING.INITIAL_TOTAL_DAYS
            )
            didScrollToFocus = false
            awaitingPastScrollAway = false
            awaitingFutureScrollAway = false
        } catch {
            errorMessage = "Failed to load program details."
        }
    }

    func handleDayAppear(_ day: DayRecord) async {
        guard pagingEnabled else { return }
        guard let index = days.firstIndex(where: { $0.id == day.id }) else { return }

        if awaitingPastScrollAway, index > 3 {
            awaitingPastScrollAway = false
        }
        if awaitingFutureScrollAway, index < days.count - 4 {
            awaitingFutureScrollAway = false
        }

        if index <= 1 {
            await loadMorePastIfNeeded()
        }
        if index >= days.count - 2 {
            await loadMoreFutureIfNeeded()
        }
    }

    private func loadMorePastIfNeeded() async {
        guard !isLoadingPast, !awaitingPastScrollAway, let first = days.first else { return }

        let earliestAllowed = programStartDate.map { Self.addDays($0, days: -CALENDAR_PAGING.PAGE_SIZE) }
        if let earliestAllowed, first.date <= earliestAllowed {
            return
        }

        isLoadingPast = true
        defer { isLoadingPast = false }
        do {
            var from = Self.addDays(first.date, days: -CALENDAR_PAGING.PAGE_SIZE)
            if let earliestAllowed, from < earliestAllowed {
                from = earliestAllowed
            }
            let span = Self.dayDistance(from, first.date)
            guard span > 0 else { return }

            let more = try await api.fetchCalendar(
                type: programType,
                from: from,
                days: span
            )
            let existing = Set(days.map(\.id))
            let unique = more.filter { !existing.contains($0.id) }
            guard !unique.isEmpty else { return }
            days.insert(contentsOf: unique, at: 0)
            awaitingPastScrollAway = true
        } catch {
            errorMessage = "Could not load earlier days."
        }
    }

    private func loadMoreFutureIfNeeded() async {
        guard !isLoadingFuture, !awaitingFutureScrollAway, let last = days.last else { return }

        let latestAllowed = programEndDate.map { Self.addDays($0, days: CALENDAR_PAGING.PAGE_SIZE) }
        if let latestAllowed, last.date >= latestAllowed {
            return
        }

        isLoadingFuture = true
        defer { isLoadingFuture = false }
        do {
            let from = Self.addDays(last.date, days: 1)
            var count = CALENDAR_PAGING.PAGE_SIZE
            if let latestAllowed {
                let remaining = Self.dayDistance(from, Self.addDays(latestAllowed, days: 1))
                guard remaining > 0 else { return }
                count = min(count, remaining)
            }

            let more = try await api.fetchCalendar(
                type: programType,
                from: from,
                days: count
            )
            let existing = Set(days.map(\.id))
            let unique = more.filter { !existing.contains($0.id) }
            guard !unique.isEmpty else { return }
            days.append(contentsOf: unique)
            awaitingFutureScrollAway = true
        } catch {
            errorMessage = "Could not load later days."
        }
    }

    func consumeInitialScroll() -> String? {
        guard !didScrollToFocus else { return nil }
        didScrollToFocus = true
        return focusDayId
    }

    func enablePagingAfterInitialScroll() {
        pagingEnabled = true
    }

    func completeExercise(_ exercise: ScheduledExercise) async {
        do {
            let response = try await api.completeExercise(id: exercise.id)
            if response.promptFeedback {
                feedbackExercise = response.exercise
            }
            await refreshVisibleRange()
        } catch {
            errorMessage = "Could not complete exercise."
        }
    }

    func submitFeedback(status: PERFORMANCE_STATUS, adjustments: ExerciseAdjustment) async {
        guard let exercise = feedbackExercise else { return }
        do {
            _ = try await api.submitFeedback(
                id: exercise.id,
                request: FeedbackRequest(status: status, adjustments: adjustments)
            )
            feedbackExercise = nil
            await refreshVisibleRange()
        } catch {
            errorMessage = "Could not save feedback."
        }
    }

    func moveSelectedSession(toWeekday weekday: String) async {
        guard let session = moveSessionTarget else { return }
        do {
            _ = try await api.moveSession(
                id: session.id,
                request: MoveSessionRequest(targetDate: nil, targetWeekday: weekday)
            )
            moveSessionTarget = nil
            await refreshVisibleRange()
        } catch {
            errorMessage = "Could not move session."
        }
    }

    private func refreshVisibleRange() async {
        guard let first = days.first else {
            await load()
            return
        }
        do {
            let refreshed = try await api.fetchCalendar(
                type: programType,
                from: first.date,
                days: max(days.count, CALENDAR_PAGING.INITIAL_TOTAL_DAYS)
            )
            days = refreshed
        } catch {
            errorMessage = "Failed to refresh schedule."
        }
    }

    private static func dayDistance(_ a: String, _ b: String) -> Int {
        guard let da = parseIso(a), let db = parseIso(b) else { return 0 }
        return Calendar.current.dateComponents([.day], from: da, to: db).day ?? 0
    }

    private static func startOfWeekMonday(_ iso: String) -> String {
        guard let date = parseIso(iso) else { return iso }
        var calendar = Calendar(identifier: .gregorian)
        calendar.firstWeekday = 2
        let weekday = calendar.component(.weekday, from: date)
        let daysFromMonday = (weekday + 5) % 7
        let monday = calendar.date(byAdding: .day, value: -daysFromMonday, to: date) ?? date
        return isoString(monday)
    }

    private static func addDays(_ iso: String, days: Int) -> String {
        guard let date = parseIso(iso) else { return iso }
        let next = Calendar.current.date(byAdding: .day, value: days, to: date) ?? date
        return isoString(next)
    }

    private static func parseIso(_ iso: String) -> Date? {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.date(from: iso)
    }

    private static func isoString(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
}
