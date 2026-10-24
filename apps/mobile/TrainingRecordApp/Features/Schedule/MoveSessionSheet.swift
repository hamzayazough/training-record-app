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
        VStack(alignment: .leading, spacing: 20) {
            VStack(spacing: 6) {
                Text("Move session")
                    .font(.title3.weight(.bold))
                    .foregroundStyle(APP_COLORS.NAVY)
                Text(session.sessionLabel)
                    .font(.subheadline)
                    .foregroundStyle(APP_COLORS.MUTED_TEXT)
            }
            .frame(maxWidth: .infinity)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                ForEach(WEEKDAY.allCases, id: \.self) { day in
                    Button {
                        selectedWeekday = day
                    } label: {
                        Text(day.rawValue.capitalized)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(selectedWeekday == day ? .white : APP_COLORS.NAVY)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(selectedWeekday == day ? APP_COLORS.NAVY : APP_COLORS.BACKGROUND)
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    }
                    .buttonStyle(.plain)
                }
            }

            Spacer(minLength: 0)

            PrimaryButton(title: "Move to \(selectedWeekday.rawValue.capitalized)") {
                onMove(selectedWeekday.rawValue)
            }

            Button("Cancel", action: onCancel)
                .frame(maxWidth: .infinity)
                .foregroundStyle(APP_COLORS.MUTED_TEXT)
        }
        .padding(.horizontal, 20)
        .padding(.top, 28)
        .padding(.bottom, 16)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(Color.white.ignoresSafeArea())
    }
}
