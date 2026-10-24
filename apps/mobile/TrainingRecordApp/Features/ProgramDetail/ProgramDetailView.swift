import SwiftUI

struct ProgramDetailView: View {
    @StateObject private var viewModel: ProgramDetailViewModel
    @State private var scrollToDayId: String?

    init(programType: PROGRAM_TYPE) {
        _viewModel = StateObject(wrappedValue: ProgramDetailViewModel(programType: programType))
    }

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    VerticalDayList(
                        days: viewModel.days,
                        labelForDay: { viewModel.displayLabel(for: $0) },
                        onAppearDay: { day in
                            Task { await viewModel.handleDayAppear(day) }
                        }
                    )

                    if viewModel.isLoadingPast || viewModel.isLoadingFuture {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
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
            .navigationDestination(for: PROGRAM_ROUTE.self) { route in
                switch route {
                case .dayDetail(let dayId):
                    DayDetailView(viewModel: viewModel, dayId: dayId)
                }
            }
            .task {
                await viewModel.load()
                scrollToDayId = viewModel.consumeInitialScroll()
            }
            .onChange(of: scrollToDayId) { _, newId in
                guard let newId else { return }
                DispatchQueue.main.async {
                    proxy.scrollTo(newId, anchor: .center)
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                        proxy.scrollTo(newId, anchor: .center)
                        viewModel.enablePagingAfterInitialScroll()
                    }
                }
            }
        }
    }
}
