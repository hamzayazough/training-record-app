import SwiftUI

struct DayDetailView: View {
    @ObservedObject var viewModel: ProgramDetailViewModel
    @State private var selectedDayId: String

    init(viewModel: ProgramDetailViewModel, dayId: String) {
        self.viewModel = viewModel
        _selectedDayId = State(initialValue: dayId)
    }

    private var selectedDay: DayRecord? {
        viewModel.days.first(where: { $0.id == selectedDayId })
    }

    var body: some View {
        TabView(selection: $selectedDayId) {
            ForEach(viewModel.days) { day in
                dayPage(for: day)
                    .tag(day.id)
            }
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
        .background(APP_COLORS.BACKGROUND.ignoresSafeArea())
        .background(NavigationPopGestureControl(isEnabled: false))
        .navigationTitle(selectedDay?.dayTitle ?? "Day")
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

    private func dayPage(for day: DayRecord) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                if day.sessions.isEmpty {
                    Text(
                        viewModel.isWithinProgram(day.date)
                            ? "Rest day — no training scheduled."
                            : "Outside the current program block."
                    )
                    .font(.subheadline)
                    .foregroundStyle(APP_COLORS.MUTED_TEXT)
                } else {
                    ProgramSectionHeader(type: viewModel.programType, sessions: day.sessions)

                    ForEach(day.sessions) { session in
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
            }
            .padding(APP_LAYOUT.HORIZONTAL_PADDING)
            .padding(.bottom, 32)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}
