import SwiftUI

struct MoveSessionSheet: View {
    let session: ScheduledSession
    let onMove: (String) -> Void
    let onCancel: () -> Void

    @State private var selectedWeekday: WEEKDAY

    init(session: ScheduledSession, onMove: @escaping (String) -> Void, onCancel: @escaping () -> Void) {
        self.session = session
        self.onMove = onMove
        self.onCancel = onCancel
        _selectedWeekday = State(initialValue: session.weekday)
    }

    var body: some View {
        VStack(spacing: 18) {
            Capsule()
                .fill(Color.gray.opacity(0.35))
                .frame(width: 42, height: 5)
                .padding(.top, 10)

            Text("Move session")
                .font(.title3.weight(.bold))
                .foregroundStyle(APP_COLORS.NAVY)

            Text(session.sessionLabel)
                .font(.subheadline)
                .foregroundStyle(APP_COLORS.MUTED_TEXT)

            Picker("Weekday", selection: $selectedWeekday) {
                ForEach(WEEKDAY.allCases, id: \.self) { day in
                    Text(day.rawValue.capitalized).tag(day)
                }
            }
            .pickerStyle(.wheel)
            .frame(height: 140)

            PrimaryButton(title: "Move to \(selectedWeekday.rawValue.capitalized)") {
                onMove(selectedWeekday.rawValue)
            }

            Button("Cancel", action: onCancel)
                .foregroundStyle(APP_COLORS.MUTED_TEXT)
                .padding(.bottom, 8)
        }
        .padding(.horizontal, 20)
        .background(APP_COLORS.SURFACE)
    }
}
