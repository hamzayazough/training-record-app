import SwiftUI

struct CombinedDayDetailView: View {
    @ObservedObject var homeViewModel: HomeViewModel
    @StateObject private var viewModel: CombinedDayDetailViewModel
    let dayId: String

    init(homeViewModel: HomeViewModel, dayId: String) {
        self.homeViewModel = homeViewModel
        self.dayId = dayId
        _viewModel = StateObject(
            wrappedValue: CombinedDayDetailViewModel {
                await homeViewModel.load()
            }
        )
    }

    private var day: DayRecord? {
        homeViewModel.day(forId: dayId)
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
            VStack(alignment: .leading, spacing: 20) {
                if day.sessions.isEmpty {
                    Text("Rest day — no training scheduled.")
                        .font(.subheadline)
                        .foregroundStyle(APP_COLORS.MUTED_TEXT)
                } else {
                    ForEach(PROGRAM_TYPE.allCases, id: \.self) { type in
                        let sessions = day.sessions.filter { $0.programType == type }
                        if !sessions.isEmpty {
                            programSection(type: type, sessions: sessions, isInteractive: day.isToday)
                        }
                    }
                }

                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                        .font(.footnote)
                        .foregroundStyle(APP_COLORS.STATUS_BAD)
                }
            }
            .padding(APP_LAYOUT.HORIZONTAL_PADDING)
            .padding(.bottom, 32)
        }
    }

    private func programSection(
        type: PROGRAM_TYPE,
        sessions: [ScheduledSession],
        isInteractive: Bool
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(type.title)
                .font(.headline.weight(.bold))
                .foregroundStyle(APP_COLORS.NAVY)

            ForEach(sessions) { session in
                Text(session.shortTrainingLabel)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(APP_COLORS.MUTED_TEXT)

                ForEach(session.exercises) { exercise in
                    ExerciseRow(
                        exercise: exercise,
                        isInteractive: isInteractive,
                        isCompact: false,
                        onToggle: {
                            Task { await viewModel.completeExercise(exercise) }
                        }
                    )
                }
            }
        }
    }
}
