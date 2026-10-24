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
                    blockPicker

                    VStack(alignment: .leading, spacing: 8) {
                        Text(headerTitle)
                            .font(.headline)
                            .foregroundStyle(APP_COLORS.NAVY)
                        Text(headerSubtitle)
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
                                guard viewModel.canSaveSelectedBlock else { return }
                                viewModel.assign(dayNumber: dayNumber, to: day.weekday)
                            },
                            onDragStart: { viewModel.beginDrag($0) },
                            onDragEnd: { viewModel.endDrag() }
                        )
                        .opacity(viewModel.canSaveSelectedBlock ? 1 : 0.55)
                        .allowsHitTesting(viewModel.canSaveSelectedBlock)
                    }
                }
                .padding(.horizontal, APP_LAYOUT.HORIZONTAL_PADDING)
                .padding(.top, 12)
                .padding(.bottom, REARRANGE_LAYOUT.POOL_MAX_HEIGHT + 32)
            }

            footer
        }
        .overlay(alignment: .bottomTrailing) {
            if viewModel.canSaveSelectedBlock {
                floatingTrainingsPool
                    .padding(.trailing, APP_LAYOUT.HORIZONTAL_PADDING)
                    .padding(.bottom, REARRANGE_LAYOUT.POOL_BOTTOM_OFFSET)
            }
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

    private var headerTitle: String {
        viewModel.selectedBlock?.name ?? "Training block"
    }

    private var headerSubtitle: String {
        if let block = viewModel.selectedBlock {
            if block.isPast {
                return "\(block.weekRangeLabel). This block is finished."
            }
            return "\(block.weekRangeLabel). Drag trainings onto a day. Saves only this block."
        }
        return "Drag trainings from the tray onto a day. Empty days stay Rest."
    }

    private var blockPicker: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Block")
                .font(.caption.weight(.bold))
                .foregroundStyle(APP_COLORS.MUTED_TEXT)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(viewModel.blocks) { block in
                        Button {
                            Task { await viewModel.selectBlock(block.id) }
                        } label: {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(block.name)
                                    .font(.caption.weight(.bold))
                                    .lineLimit(1)
                                Text(block.weekRangeLabel)
                                    .font(.caption2.weight(.semibold))
                                    .opacity(0.8)
                            }
                            .foregroundStyle(chipForeground(for: block))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 10)
                            .background(chipBackground(for: block))
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .stroke(chipStroke(for: block), lineWidth: 1)
                            )
                        }
                        .buttonStyle(.plain)
                        .disabled(viewModel.isLoading || viewModel.isSaving)
                    }
                }
            }
        }
    }

    private func chipForeground(for block: RearrangeBlock) -> Color {
        if block.id == viewModel.selectedBlockId { return .white }
        if block.isPast { return APP_COLORS.MUTED_TEXT }
        return APP_COLORS.NAVY
    }

    private func chipBackground(for block: RearrangeBlock) -> Color {
        if block.id == viewModel.selectedBlockId { return APP_COLORS.NAVY }
        return APP_COLORS.SURFACE
    }

    private func chipStroke(for block: RearrangeBlock) -> Color {
        if block.id == viewModel.selectedBlockId { return .clear }
        if block.isCurrent { return APP_COLORS.ACCENT_ORANGE.opacity(0.55) }
        return Color.black.opacity(0.06)
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
                title: saveButtonTitle,
                action: { Task { await viewModel.save() } }
            )
            .disabled(
                viewModel.isSaving
                    || viewModel.isLoading
                    || !viewModel.canSaveSelectedBlock
            )
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

    private var saveButtonTitle: String {
        if viewModel.isSaving { return "Saving…" }
        if !viewModel.canSaveSelectedBlock { return "Block finished" }
        return "Save this block"
    }
}
