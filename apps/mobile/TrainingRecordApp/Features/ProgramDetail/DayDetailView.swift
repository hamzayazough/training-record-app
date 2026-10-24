import SwiftUI

struct DayDetailView: View {
    @ObservedObject var viewModel: ProgramDetailViewModel
    let dayId: String

    private var day: DayRecord? {
        viewModel.days.first(where: { $0.id == dayId })
    }

    var body: some View {
        Group {
            if let day {
                content(for: day)
            } else {
                Text("Session not found")
                    .foregroundStyle(APP_COLORS.MUTED_TEXT)
            }
        }
        .background(APP_COLORS.BACKGROUND.ignoresSafeArea())
        .navigationTitle(day?.dayTitle ?? "Day")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $viewModel.feedbackExercise) { exercise in
            FeedbackBottomSheet(
                exercise: exercise,
                onSubmit: { status, adjustments in
                    Task { await viewModel.submitFeedback(status: status, adjustments: adjustments) }
                },
                onCancel: { viewModel.feedbackExercise = nil }
            )
        }
    }

    private func content(for day: DayRecord) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(viewModel.displayLabel(for: day).isEmpty ? "No session" : viewModel.displayLabel(for: day))
                        .font(.title2.weight(.bold))
                        .foregroundStyle(APP_COLORS.NAVY)
                    if let weekNumber = day.weekNumber {
                        Text("Week \(weekNumber)")
                            .font(.subheadline)
                            .foregroundStyle(APP_COLORS.MUTED_TEXT)
                    }
                }

                if day.sessions.isEmpty {
                    Text(viewModel.isWithinProgram(day.date) ? "Rest day — no training scheduled." : "Outside the current program block.")
                        .font(.subheadline)
                        .foregroundStyle(APP_COLORS.MUTED_TEXT)
                        .padding(.top, 8)
                }

                ForEach(day.sessions) { session in
                    if day.sessions.count > 1 {
                        Text(session.sessionLabel)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(APP_COLORS.MUTED_TEXT)
                    }
                    ForEach(session.exercises) { exercise in
                        ExerciseRow(
                            exercise: exercise,
                            isInteractive: day.isToday,
                            isCompact: false,
                            onToggle: {
                                Task { await viewModel.completeExercise(exercise) }
                            }
                        )
                    }
                }
            }
            .padding(APP_LAYOUT.HORIZONTAL_PADDING)
            .padding(.bottom, 32)
        }
    }
}
