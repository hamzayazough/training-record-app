import SwiftUI

struct HomeView: View {
    @StateObject private var viewModel = HomeViewModel()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    AppHeader(
                        title: "Let's train today",
                        subtitle: "Your next five days at a glance"
                    )

                    HorizontalDayStrip(days: viewModel.calendarDays)

                    VStack(spacing: 16) {
                        NavigationLink(value: PROGRAM_TYPE.ENDURANCE) {
                            ProgramHeroCard(
                                type: .ENDURANCE,
                                subtitle: viewModel.subtitle(for: .ENDURANCE),
                                todayLabel: viewModel.todayTrainingLabel(for: .ENDURANCE),
                                todayCompleted: viewModel.todayTrainingCompleted(for: .ENDURANCE)
                            )
                        }
                        .buttonStyle(.plain)

                        NavigationLink(value: PROGRAM_TYPE.CALISTHENICS) {
                            ProgramHeroCard(
                                type: .CALISTHENICS,
                                subtitle: viewModel.subtitle(for: .CALISTHENICS),
                                todayLabel: viewModel.todayTrainingLabel(for: .CALISTHENICS),
                                todayCompleted: viewModel.todayTrainingCompleted(for: .CALISTHENICS)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, APP_LAYOUT.HORIZONTAL_PADDING)

                    if let errorMessage = viewModel.errorMessage {
                        Text(errorMessage)
                            .font(.footnote)
                            .foregroundStyle(APP_COLORS.STATUS_BAD)
                            .padding(.horizontal, APP_LAYOUT.HORIZONTAL_PADDING)
                    }
                }
                .padding(.bottom, 32)
            }
            .background(APP_COLORS.BACKGROUND.ignoresSafeArea())
            .navigationBarHidden(true)
            .navigationDestination(for: PROGRAM_TYPE.self) { type in
                ProgramDetailView(programType: type)
            }
            .navigationDestination(for: HOME_ROUTE.self) { route in
                switch route {
                case .dayDetail(let dayId):
                    CombinedDayDetailView(homeViewModel: viewModel, dayId: dayId)
                }
            }
            .task { await viewModel.load() }
            .refreshable { await viewModel.load() }
        }
    }
}
