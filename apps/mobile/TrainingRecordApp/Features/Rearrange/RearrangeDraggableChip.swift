import SwiftUI

struct RearrangeDraggableChip: View {
    let training: RearrangeTraining
    let isDragging: Bool
    let onDragStart: () -> Void
    let onDragEnd: () -> Void

    var body: some View {
        RearrangeTrainingChip(label: training.label)
            .opacity(isDragging ? 0 : 1)
            .draggable(REARRANGE_DRAG.training(training.dayNumber)) {
                RearrangeTrainingChip(label: training.label)
                    .frame(width: 260)
                    .onAppear(perform: onDragStart)
                    .onDisappear(perform: onDragEnd)
            }
    }
}
