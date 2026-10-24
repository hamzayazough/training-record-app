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
                                subtitle: viewModel.subtitle(for: .ENDURANCE)
                            )
                        }
                        .buttonStyle(.plain)

                        NavigationLink(value: PROGRAM_TYPE.CALISTHENICS) {
                            ProgramHeroCard(
                                type: .CALISTHENICS,
                                subtitle: viewModel.subtitle(for: .CALISTHENICS)
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
            .task { await viewModel.load() }
            .refreshable { await viewModel.load() }
        }
    }
}
