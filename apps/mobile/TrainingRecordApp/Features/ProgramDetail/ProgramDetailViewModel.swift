import Foundation

@MainActor
final class ProgramDetailViewModel: ObservableObject {
    @Published var days: [DayRecord] = []
    @Published var selectedSession: ScheduledSession?
    @Published var feedbackExercise: ScheduledExercise?
    @Published var moveSessionTarget: ScheduledSession?
    @Published var errorMessage: String?
    @Published var isLoading = false

    let programType: PROGRAM_TYPE
    private let api: TrainingAPIClient

    init(programType: PROGRAM_TYPE, api: TrainingAPIClient = .SHARED) {
        self.programType = programType
        self.api = api
    }

    var todaySessions: [ScheduledSession] {
        days.first(where: \.isToday)?.sessions ?? []
    }

    /// Training days only — omit empty Rest placeholders that pad the calendar.
    var scheduledDays: [DayRecord] {
        days.filter { !$0.sessions.isEmpty }
    }

    func load() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            days = try await api.fetchDetail(type: programType)
            if let selected = selectedSession,
               let refreshed = days.flatMap(\.sessions).first(where: { $0.id == selected.id }) {
                selectedSession = refreshed
            }
        } catch {
            errorMessage = "Failed to load program details."
        }
    }

    func completeExercise(_ exercise: ScheduledExercise) async {
        do {
            let response = try await api.completeExercise(id: exercise.id)
            if response.promptFeedback {
                feedbackExercise = response.exercise
            }
            await load()
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
            await load()
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
            await load()
        } catch {
            errorMessage = "Could not move session."
        }
    }
}
