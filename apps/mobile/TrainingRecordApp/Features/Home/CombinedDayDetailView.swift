import SwiftUI

struct CombinedDayDetailView: View {
    @ObservedObject var homeViewModel: HomeViewModel
    @StateObject private var viewModel: CombinedDayDetailViewModel
    @State private var selectedDayId: String

    init(homeViewModel: HomeViewModel, dayId: String) {
        self.homeViewModel = homeViewModel
        _selectedDayId = State(initialValue: dayId)
        _viewModel = StateObject(
            wrappedValue: CombinedDayDetailViewModel {
                await homeViewModel.load()
            }
        )
    }

    private var selectedDay: DayRecord? {
        homeViewModel.day(forId: selectedDayId)
    }

    var body: some View {
        TabView(selection: $selectedDayId) {
            ForEach(homeViewModel.calendarDays) { day in
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
            VStack(alignment: .leading, spacing: 24) {
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
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func programSection(
        type: PROGRAM_TYPE,
        sessions: [ScheduledSession],
        isInteractive: Bool
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            ProgramSectionHeader(type: type, sessions: sessions)

            ForEach(sessions) { session in
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
