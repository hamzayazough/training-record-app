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
                        Text("This week")
                            .font(.headline)
                            .foregroundStyle(APP_COLORS.NAVY)
                        Text("Drag trainings from the tray onto a day. Empty days stay Rest.")
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
                            onDragStart: { viewModel.beginDrag($0) },
                            onDragEnd: { viewModel.endDrag() }
                        )
                    }
                }
                .padding(.horizontal, APP_LAYOUT.HORIZONTAL_PADDING)
                .padding(.top, 12)
                .padding(.bottom, REARRANGE_LAYOUT.POOL_MAX_HEIGHT + 32)
            }

            footer
        }
        .overlay(alignment: .bottomTrailing) {
            floatingTrainingsPool
                .padding(.trailing, APP_LAYOUT.HORIZONTAL_PADDING)
                .padding(.bottom, REARRANGE_LAYOUT.POOL_BOTTOM_OFFSET)
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

    private var floatingTrainingsPool: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Trainings")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(APP_COLORS.MUTED_TEXT)
                Spacer(minLength: 0)
                Button("Reset") {
                    viewModel.resetTrainings()
                }
                .font(.caption.weight(.bold))
                .foregroundStyle(APP_COLORS.ACCENT_ORANGE)
                .disabled(viewModel.unassignedTrainings.count == viewModel.trainings.count)
            }

            if viewModel.unassignedTrainings.isEmpty {
                Text("All placed")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(APP_COLORS.MUTED_TEXT)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 6)
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 8) {
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
                .frame(maxHeight: REARRANGE_LAYOUT.POOL_MAX_HEIGHT)
            }
        }
        .padding(12)
        .frame(width: REARRANGE_LAYOUT.POOL_WIDTH, alignment: .leading)
        .background(APP_COLORS.SURFACE)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color.black.opacity(0.06), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.14), radius: 16, y: 6)
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
