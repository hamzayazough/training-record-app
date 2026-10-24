import SwiftUI

struct FeedbackBottomSheet: View {
    let exercise: ScheduledExercise
    let onSubmit: (PERFORMANCE_STATUS, ExerciseAdjustment) -> Void
    let onCancel: () -> Void

    @State private var selectedStatus: PERFORMANCE_STATUS = .GOOD
    @State private var detent: PresentationDetent = .height(300)
    @State private var weight = ""
    @State private var reps = ""
    @State private var sets = ""
    @State private var distance = ""
    @State private var pace = ""
    @State private var duration = ""
    @State private var notes = ""

    private var showsAdjustmentFields: Bool {
        selectedStatus == .SO_SO
    }

    var body: some View {
        VStack(spacing: 20) {
            Text("How did it go?")
                .font(.title3.weight(.bold))
                .foregroundStyle(APP_COLORS.NAVY)

            Text(exercise.prescription.isEmpty ? exercise.name : exercise.prescription)
                .font(.subheadline)
                .foregroundStyle(APP_COLORS.MUTED_TEXT)
                .multilineTextAlignment(.center)
                .lineLimit(3)

            HStack(spacing: 10) {
                statusChip(.GOOD, title: "Good")
                statusChip(.SO_SO, title: "So-so")
                statusChip(.BAD, title: "Missed")
            }

            if showsAdjustmentFields {
                ScrollView {
                    VStack(spacing: 12) {
                        if exercise.metrics.contains("WEIGHT") {
                            field("Weight / load", text: $weight)
                        }
                        if exercise.metrics.contains("REPS") {
                            field("Reps", text: $reps)
                        }
                        if exercise.metrics.contains("SETS") {
                            field("Sets", text: $sets)
                        }
                        if exercise.metrics.contains("DISTANCE") {
                            field("Distance", text: $distance)
                        }
                        if exercise.metrics.contains("PACE") {
                            field("Pace", text: $pace)
                        }
                        if exercise.metrics.contains("DURATION") {
                            field("Time / duration", text: $duration)
                        }
                        field("Notes", text: $notes)
                    }
                }
            }

            PrimaryButton(title: "Confirm") {
                let adjustments = showsAdjustmentFields
                    ? ExerciseAdjustment(
                        weight: weight.nilIfEmpty,
                        reps: reps.nilIfEmpty,
                        sets: sets.nilIfEmpty,
                        distance: distance.nilIfEmpty,
                        pace: pace.nilIfEmpty,
                        duration: duration.nilIfEmpty,
                        notes: notes.nilIfEmpty
                    )
                    : ExerciseAdjustment()
                onSubmit(selectedStatus, adjustments)
            }

            Button("Cancel", action: onCancel)
                .foregroundStyle(APP_COLORS.MUTED_TEXT)
        }
        .padding(.horizontal, 20)
        .padding(.top, 28)
        .padding(.bottom, 16)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(Color.white.ignoresSafeArea())
        .presentationDetents([.height(300), .large], selection: $detent)
        .presentationDragIndicator(.visible)
        .presentationBackground(Color.white)
        .onChange(of: selectedStatus) { _, status in
            withAnimation(.snappy) {
                detent = status == .SO_SO ? .large : .height(300)
            }
        }
    }

    private func statusChip(_ status: PERFORMANCE_STATUS, title: String) -> some View {
        Button {
            selectedStatus = status
        } label: {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(selectedStatus == status ? .white : APP_COLORS.NAVY)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(selectedStatus == status ? status.color : APP_COLORS.BACKGROUND)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private func field(_ title: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(APP_COLORS.MUTED_TEXT)
            TextField(title, text: text)
                .padding(12)
                .background(APP_COLORS.BACKGROUND)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
    }
}

private extension String {
    var nilIfEmpty: String? {
        isEmpty ? nil : self
    }
}
