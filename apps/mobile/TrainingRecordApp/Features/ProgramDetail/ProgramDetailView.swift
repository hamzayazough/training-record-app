import SwiftUI

struct ProgramDetailView: View {
    @StateObject private var viewModel: ProgramDetailViewModel

    init(programType: PROGRAM_TYPE) {
        _viewModel = StateObject(wrappedValue: ProgramDetailViewModel(programType: programType))
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                VerticalDayList(
                    days: viewModel.scheduledDays,
                    onToggleExercise: { exercise in
                        Task { await viewModel.completeExercise(exercise) }
                    },
                    onMoveSession: { session in
                        viewModel.moveSessionTarget = session
                    }
                )

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
        }
        .sheet(item: $viewModel.moveSessionTarget) { session in
            MoveSessionSheet(
                session: session,
                onMove: { weekday in
                    Task { await viewModel.moveSelectedSession(toWeekday: weekday) }
                },
                onCancel: { viewModel.moveSessionTarget = nil }
            )
            .presentationDetents([.height(420), .medium])
            .presentationDragIndicator(.visible)
            .presentationBackground(Color.white)
        }
    }
}
