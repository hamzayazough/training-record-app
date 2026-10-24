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
                .padding(.bottom, 24)
            }
            .safeAreaInset(edge: .bottom) {
                rearrangeFooter
            }
            .background(APP_COLORS.BACKGROUND.ignoresSafeArea())
            .navigationTitle(viewModel.programType.title)
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(for: PROGRAM_ROUTE.self) { route in
                switch route {
                case .dayDetail(let dayId):
                    DayDetailView(viewModel: viewModel, dayId: dayId)
                case .rearrange:
                    RearrangeScheduleView(programType: viewModel.programType) {
                        Task { await viewModel.load() }
                    }
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

    private var rearrangeFooter: some View {
        NavigationLink(value: PROGRAM_ROUTE.rearrange) {
            Text("Rearrange training days")
                .font(.headline.weight(.semibold))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(APP_COLORS.NAVY)
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
        .buttonStyle(.plain)
        .padding(.horizontal, APP_LAYOUT.HORIZONTAL_PADDING)
        .padding(.top, 12)
        .padding(.bottom, 10)
        .background(
            APP_COLORS.SURFACE
                .shadow(color: .black.opacity(0.08), radius: 12, y: -4)
                .ignoresSafeArea(edges: .bottom)
        )
    }
}
