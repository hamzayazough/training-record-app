import SwiftUI

struct RearrangeDayDropZone: View {
    let day: RearrangeWeekDay
    let trainings: [RearrangeTraining]
    let isToday: Bool
    let draggingDayNumber: Int?
    let onDrop: (Int) -> Void
    let onDragStart: (Int) -> Void
    let onDragEnd: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(day.shortLabel)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(APP_COLORS.MUTED_TEXT)
                Text(dayNumber)
                    .font(.title3.weight(.bold))
                    .foregroundStyle(APP_COLORS.NAVY)
                if isToday {
                    Text("Today")
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(APP_COLORS.PRIMARY_GREEN)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(APP_COLORS.PRIMARY_GREEN.opacity(0.12))
                        .clipShape(Capsule())
                }
                Spacer()
            }

            if trainings.isEmpty {
                Text("Rest")
                    .font(.subheadline)
                    .foregroundStyle(APP_COLORS.MUTED_TEXT)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 8)
            } else {
                ForEach(trainings) { training in
                    RearrangeDraggableChip(
                        training: training,
                        isDragging: draggingDayNumber == training.dayNumber,
                        onDragStart: { onDragStart(training.dayNumber) },
                        onDragEnd: onDragEnd
                    )
                }
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(isToday ? APP_COLORS.PRIMARY_GREEN.opacity(0.06) : APP_COLORS.SURFACE)
        .clipShape(RoundedRectangle(cornerRadius: APP_LAYOUT.CORNER_RADIUS, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: APP_LAYOUT.CORNER_RADIUS, style: .continuous)
                .stroke(isToday ? APP_COLORS.PRIMARY_GREEN.opacity(0.45) : Color.black.opacity(0.05), lineWidth: isToday ? 2 : 1)
        )
        .dropDestination(for: REARRANGE_DRAG.self) { items, _ in
            guard let item = items.first else { return false }
            onDrop(item.dayNumber)
            onDragEnd()
            return true
        }
    }

    private var dayNumber: String {
        let parts = day.date.split(separator: "-")
        guard parts.count == 3 else { return day.date }
        return String(parts[2])
    }
}
