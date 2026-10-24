import SwiftUI

struct ProgramDetailView: View {
    @StateObject private var viewModel: ProgramDetailViewModel

    init(programType: PROGRAM_TYPE) {
        _viewModel = StateObject(wrappedValue: ProgramDetailViewModel(programType: programType))
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                if !viewModel.todaySessions.isEmpty {
                    todaySection
                }

                Text("Schedule")
                    .font(.title3.weight(.bold))
                    .foregroundStyle(APP_COLORS.NAVY)
                    .padding(.horizontal, APP_LAYOUT.HORIZONTAL_PADDING)

                VerticalDayList(days: viewModel.scheduledDays) { session in
                    viewModel.selectedSession = session
                }

                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                        .font(.footnote)
                        .foregroundStyle(APP_COLORS.STATUS_BAD)
                        .padding(.horizontal, APP_LAYOUT.HORIZONTAL_PADDING)
                }
            }
            .padding(.top, 8)
            .padding(.bottom, 40)
        }
        .background(APP_COLORS.BACKGROUND.ignoresSafeArea())
        .navigationTitle(viewModel.programType.title)
        .navigationBarTitleDisplayMode(.inline)
        .task { await viewModel.load() }
        .sheet(item: $viewModel.feedbackExercise) { exercise in
            FeedbackBottomSheet(
                exercise: exercise,
                onSubmit: { status, adjustments in
                    Task { await viewModel.submitFeedback(status: status, adjustments: adjustments) }
                },
                onCancel: { viewModel.feedbackExercise = nil }
            )
            .presentationDetents([.medium, .large])
        }
        .sheet(item: $viewModel.moveSessionTarget) { session in
            MoveSessionSheet(
                session: session,
                onMove: { weekday in
                    Task { await viewModel.moveSelectedSession(toWeekday: weekday) }
                },
                onCancel: { viewModel.moveSessionTarget = nil }
            )
            .presentationDetents([.medium])
        }
        .sheet(item: $viewModel.selectedSession) { session in
            sessionDetail(session)
                .presentationDetents([.medium, .large])
        }
    }

    private var todaySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Today")
                .font(.title3.weight(.bold))
                .foregroundStyle(APP_COLORS.NAVY)
                .padding(.horizontal, APP_LAYOUT.HORIZONTAL_PADDING)

            ForEach(viewModel.todaySessions) { session in
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text(session.sessionLabel)
                            .font(.headline)
                            .foregroundStyle(APP_COLORS.NAVY)
                        Spacer()
                        Button("Move") {
                            viewModel.moveSessionTarget = session
                        }
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(APP_COLORS.ACCENT_ORANGE)
                    }
                    .padding(.horizontal, APP_LAYOUT.HORIZONTAL_PADDING)

                    ForEach(session.exercises) { exercise in
                        ExerciseRow(
                            exercise: exercise,
                            isInteractive: true,
                            onToggle: {
                                Task { await viewModel.completeExercise(exercise) }
                            }
                        )
                        .padding(.horizontal, APP_LAYOUT.HORIZONTAL_PADDING)
                    }
                }
            }
        }
    }

    private func sessionDetail(_ session: ScheduledSession) -> some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    Text(session.sessionLabel)
                        .font(.title2.weight(.bold))
                        .foregroundStyle(APP_COLORS.NAVY)
                    Text("\(session.weekday.rawValue.capitalized) · Week \(session.weekNumber)")
                        .font(.subheadline)
                        .foregroundStyle(APP_COLORS.MUTED_TEXT)

                    ForEach(session.exercises) { exercise in
                        ExerciseRow(
                            exercise: exercise,
                            isInteractive: session.date == DayRecord.todayIso(),
                            onToggle: {
                                Task { await viewModel.completeExercise(exercise) }
                            }
                        )
                    }

                    PrimaryButton(title: "Move session", background: APP_COLORS.NAVY) {
                        viewModel.selectedSession = nil
                        viewModel.moveSessionTarget = session
                    }
                }
                .padding(20)
            }
            .background(APP_COLORS.BACKGROUND.ignoresSafeArea())
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { viewModel.selectedSession = nil }
                }
            }
        }
    }
}
