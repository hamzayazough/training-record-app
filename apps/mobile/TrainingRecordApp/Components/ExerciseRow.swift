import SwiftUI

struct ExerciseRow: View {
    let exercise: ScheduledExercise
    let isInteractive: Bool
    var isCompact: Bool = false
    let onToggle: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Button(action: onToggle) {
                Image(systemName: exercise.completed ? "checkmark.square.fill" : "square")
                    .font(isCompact ? .body : .title3)
                    .foregroundStyle(checkboxColor)
            }
            .buttonStyle(.plain)
            .disabled(!isInteractive)

            VStack(alignment: .leading, spacing: isCompact ? 4 : 8) {
                Text(exercise.name)
                    .font(isCompact ? .subheadline.weight(.semibold) : .headline)
                    .foregroundStyle(APP_COLORS.NAVY)
                    .strikethrough(exercise.completed && exercise.status != .PENDING)

                if exercise.hasStructuredTargets {
                    VStack(alignment: .leading, spacing: 4) {
                        ForEach(exercise.detailLines, id: \.label) { line in
                            HStack(alignment: .firstTextBaseline, spacing: 8) {
                                Text(line.label)
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(APP_COLORS.MUTED_TEXT)
                                    .frame(width: isCompact ? 48 : 56, alignment: .leading)
                                Text(line.value)
                                    .font(.subheadline)
                                    .foregroundStyle(APP_COLORS.NAVY)
                            }
                        }
                    }
                } else if let fallback = exercise.fallbackPrescription {
                    Text(fallback)
                        .font(.subheadline)
                        .foregroundStyle(APP_COLORS.MUTED_TEXT)
                }

                if let adjustments = exercise.adjustments, hasAdjustment(adjustments) {
                    Text(adjustmentText(adjustments))
                        .font(.caption)
                        .foregroundStyle(APP_COLORS.ACCENT_ORANGE)
                }
            }
            Spacer(minLength: 0)
            StatusDot(status: exercise.status, size: isCompact ? 8 : 10)
        }
        .padding(isCompact ? 0 : 16)
        .background(isCompact ? Color.clear : APP_COLORS.SURFACE)
        .clipShape(RoundedRectangle(cornerRadius: isCompact ? 0 : 18, style: .continuous))
        .shadow(color: isCompact ? .clear : .black.opacity(0.04), radius: 8, y: 4)
    }

    private var checkboxColor: Color {
        if exercise.completed { return APP_COLORS.PRIMARY_GREEN }
        if !isInteractive && !exercise.completed { return APP_COLORS.STATUS_BAD.opacity(0.7) }
        return APP_COLORS.MUTED_TEXT
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
