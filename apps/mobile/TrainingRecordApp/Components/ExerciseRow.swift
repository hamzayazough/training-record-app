import SwiftUI

struct ExerciseRow: View {
    let exercise: ScheduledExercise
    let isInteractive: Bool
    let onToggle: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            Button(action: onToggle) {
                Image(systemName: exercise.completed ? "checkmark.square.fill" : "square")
                    .font(.title3)
                    .foregroundStyle(exercise.completed ? APP_COLORS.PRIMARY_GREEN : APP_COLORS.MUTED_TEXT)
            }
            .buttonStyle(.plain)
            .disabled(!isInteractive)

            VStack(alignment: .leading, spacing: 6) {
                Text(exercise.name)
                    .font(.headline)
                    .foregroundStyle(APP_COLORS.NAVY)
                    .strikethrough(exercise.completed && exercise.status != .PENDING)
                Text(exercise.prescription)
                    .font(.subheadline)
                    .foregroundStyle(APP_COLORS.MUTED_TEXT)
                if let adjustments = exercise.adjustments, hasAdjustment(adjustments) {
                    Text(adjustmentText(adjustments))
                        .font(.caption)
                        .foregroundStyle(APP_COLORS.ACCENT_ORANGE)
                }
            }
            Spacer(minLength: 0)
            StatusDot(status: exercise.status)
        }
        .padding(16)
        .background(APP_COLORS.SURFACE)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .shadow(color: .black.opacity(0.04), radius: 8, y: 4)
    }

    private func hasAdjustment(_ value: ExerciseAdjustment) -> Bool {
        [value.weight, value.reps, value.sets, value.distance, value.pace, value.duration, value.notes]
            .contains { ($0 ?? "").isEmpty == false }
    }

    private func adjustmentText(_ value: ExerciseAdjustment) -> String {
        var parts: [String] = []
        if let weight = value.weight, !weight.isEmpty { parts.append("wt \(weight)") }
        if let reps = value.reps, !reps.isEmpty { parts.append("reps \(reps)") }
        if let sets = value.sets, !sets.isEmpty { parts.append("sets \(sets)") }
        if let distance = value.distance, !distance.isEmpty { parts.append(distance) }
        if let pace = value.pace, !pace.isEmpty { parts.append(pace) }
        if let duration = value.duration, !duration.isEmpty { parts.append(duration) }
        if let notes = value.notes, !notes.isEmpty { parts.append(notes) }
        return parts.joined(separator: " · ")
    }
}
