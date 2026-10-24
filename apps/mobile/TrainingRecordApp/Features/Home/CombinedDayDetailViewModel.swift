import Foundation

@MainActor
final class CombinedDayDetailViewModel: ObservableObject {
    @Published var feedbackExercise: ScheduledExercise?
    @Published var errorMessage: String?

    private let api: TrainingAPIClient
    private let onRefresh: () async -> Void

    init(api: TrainingAPIClient = .SHARED, onRefresh: @escaping () async -> Void) {
        self.api = api
        self.onRefresh = onRefresh
    }

    func completeExercise(_ exercise: ScheduledExercise) async {
        do {
            let response = try await api.completeExercise(id: exercise.id)
            if response.promptFeedback {
                feedbackExercise = response.exercise
            }
            await onRefresh()
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
            await onRefresh()
        } catch {
            errorMessage = "Could not save feedback."
        }
    }
}
