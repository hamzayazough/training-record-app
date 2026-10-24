import SwiftUI

struct FeedbackBottomSheet: View {
    let exercise: ScheduledExercise
    let onSubmit: (PERFORMANCE_STATUS, ExerciseAdjustment) -> Void
    let onCancel: () -> Void

    @State private var selectedStatus: PERFORMANCE_STATUS = .GOOD
    @State private var weight = ""
    @State private var reps = ""
    @State private var sets = ""
    @State private var distance = ""
    @State private var pace = ""
    @State private var duration = ""
    @State private var notes = ""

    var body: some View {
        VStack(spacing: 20) {
            Capsule()
                .fill(Color.gray.opacity(0.35))
                .frame(width: 42, height: 5)
                .padding(.top, 10)

            Text("How did it go?")
                .font(.title3.weight(.bold))
                .foregroundStyle(APP_COLORS.NAVY)

            Text(exercise.name)
                .font(.subheadline)
                .foregroundStyle(APP_COLORS.MUTED_TEXT)
                .multilineTextAlignment(.center)

            HStack(spacing: 10) {
                statusChip(.GOOD, title: "Good")
                statusChip(.SO_SO, title: "So-so")
                statusChip(.BAD, title: "Missed")
            }

            if selectedStatus != .GOOD {
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

            PrimaryButton(title: "Confirm") {
                let adjustments = ExerciseAdjustment(
                    weight: weight.nilIfEmpty,
                    reps: reps.nilIfEmpty,
                    sets: sets.nilIfEmpty,
                    distance: distance.nilIfEmpty,
                    pace: pace.nilIfEmpty,
                    duration: duration.nilIfEmpty,
                    notes: notes.nilIfEmpty
                )
                onSubmit(selectedStatus, adjustments)
            }

            Button("Cancel", action: onCancel)
                .foregroundStyle(APP_COLORS.MUTED_TEXT)
                .padding(.bottom, 8)
        }
        .padding(.horizontal, 20)
        .background(APP_COLORS.SURFACE)
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
