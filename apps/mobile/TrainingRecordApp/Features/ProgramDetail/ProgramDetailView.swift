import SwiftUI

struct ProgramDetailView: View {
    @StateObject private var viewModel: ProgramDetailViewModel
    @State private var scrollPosition: String?

    init(programType: PROGRAM_TYPE) {
        _viewModel = StateObject(wrappedValue: ProgramDetailViewModel(programType: programType))
    }

    var body: some View {
        ScrollView {
            VerticalDayList(
                days: viewModel.days,
                labelForDay: { viewModel.displayLabel(for: $0) },
                isLoadingPast: viewModel.isLoadingPast,
                isLoadingFuture: viewModel.isLoadingFuture,
                onLoadPast: {
                    Task { await viewModel.loadMorePastIfNeeded() }
                },
                onLoadFuture: {
                    Task { await viewModel.loadMoreFutureIfNeeded() }
                }
            )
            .padding(.top, 8)
            .padding(.bottom, 24)

            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
                    .font(.footnote)
                    .foregroundStyle(APP_COLORS.STATUS_BAD)
                    .padding(.horizontal, APP_LAYOUT.HORIZONTAL_PADDING)
                    .padding(.bottom, 16)
            }
        }
        .scrollPosition(id: $scrollPosition, anchor: .center)
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
                    Task { await reloadAndScrollToToday() }
                }
            }
        }
        .task {
            if viewModel.hasLoaded {
                viewModel.enablePagingAfterInitialScroll()
                return
            }
            await reloadAndScrollToToday()
        }
        .onChange(of: viewModel.scrollRestoreDayId) { _, dayId in
            guard let dayId else { return }
            scrollPosition = dayId
            viewModel.clearScrollRestore()
        }
    }

    private func reloadAndScrollToToday() async {
        await viewModel.load()
        await scrollToToday()
        viewModel.enablePagingAfterInitialScroll()
    }

    private func scrollToToday() async {
        let target = viewModel.focusDayId
        scrollPosition = nil
        await Task.yield()
        scrollPosition = target
        try? await Task.sleep(nanoseconds: 100_000_000)
        scrollPosition = target
        try? await Task.sleep(nanoseconds: 250_000_000)
        scrollPosition = target
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
