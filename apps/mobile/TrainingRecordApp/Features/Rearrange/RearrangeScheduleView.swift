import SwiftUI

struct RearrangeScheduleView: View {
    @StateObject private var viewModel: RearrangeViewModel
    @Environment(\.dismiss) private var dismiss
    var onSaved: (() -> Void)?

    init(programType: PROGRAM_TYPE, onSaved: (() -> Void)? = nil) {
        _viewModel = StateObject(wrappedValue: RearrangeViewModel(programType: programType))
        self.onSaved = onSaved
    }

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Trainings")
                            .font(.headline)
                            .foregroundStyle(APP_COLORS.NAVY)
                        Text("Drag a workout onto a day below. Empty days stay Rest.")
                            .font(.footnote)
                            .foregroundStyle(APP_COLORS.MUTED_TEXT)
                    }

                    unassignedPool

                    VStack(alignment: .leading, spacing: 8) {
                        Text("This week")
                            .font(.headline)
                            .foregroundStyle(APP_COLORS.NAVY)
                        Text("Starts from today")
                            .font(.footnote)
                            .foregroundStyle(APP_COLORS.MUTED_TEXT)
                    }

                    ForEach(viewModel.weekDays) { day in
                        RearrangeDayDropZone(
                            day: day,
                            trainings: viewModel.trainings(for: day.weekday),
                            isToday: day.date == DayRecord.todayIso(),
                            draggingDayNumber: viewModel.draggingDayNumber,
                            onDrop: { dayNumber in
                                viewModel.assign(dayNumber: dayNumber, to: day.weekday)
                            },
                            onRemove: { dayNumber in
                                viewModel.assign(dayNumber: dayNumber, to: nil)
                            },
                            onDragStart: { viewModel.beginDrag($0) },
                            onDragEnd: { viewModel.endDrag() }
                        )
                    }
                }
                .padding(.horizontal, APP_LAYOUT.HORIZONTAL_PADDING)
                .padding(.top, 12)
                .padding(.bottom, 24)
            }

            footer
        }
        .background(APP_COLORS.BACKGROUND.ignoresSafeArea())
        .navigationTitle("Rearrange")
        .navigationBarTitleDisplayMode(.inline)
        .task { await viewModel.load() }
        .onChange(of: viewModel.didSave) { _, saved in
            guard saved else { return }
            onSaved?()
            dismiss()
        }
    }

    private var unassignedPool: some View {
        VStack(alignment: .leading, spacing: 10) {
            if viewModel.unassignedTrainings.isEmpty {
                Text("All trainings placed")
                    .font(.subheadline)
                    .foregroundStyle(APP_COLORS.MUTED_TEXT)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(14)
            } else {
                ForEach(viewModel.unassignedTrainings) { training in
                    RearrangeDraggableChip(
                        training: training,
                        isDragging: viewModel.isDragging(training.dayNumber),
                        onDragStart: { viewModel.beginDrag(training.dayNumber) },
                        onDragEnd: { viewModel.endDrag() }
                    )
                }
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(APP_COLORS.STATUS_REST.opacity(0.65))
        .clipShape(RoundedRectangle(cornerRadius: APP_LAYOUT.CORNER_RADIUS, style: .continuous))
        .dropDestination(for: REARRANGE_DRAG.self) { items, _ in
            guard let item = items.first else { return false }
            viewModel.assign(dayNumber: item.dayNumber, to: nil)
            viewModel.endDrag()
            return true
        }
    }

    private var footer: some View {
        VStack(spacing: 10) {
            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
                    .font(.footnote)
                    .foregroundStyle(APP_COLORS.STATUS_BAD)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            PrimaryButton(
                title: viewModel.isSaving ? "Saving…" : "Save arrangement",
                action: { Task { await viewModel.save() } }
            )
            .disabled(viewModel.isSaving || viewModel.isLoading)
        }
        .padding(.horizontal, APP_LAYOUT.HORIZONTAL_PADDING)
        .padding(.top, 12)
        .padding(.bottom, 16)
        .background(
            APP_COLORS.SURFACE
                .shadow(color: .black.opacity(0.08), radius: 12, y: -4)
                .ignoresSafeArea(edges: .bottom)
        )
    }
}
