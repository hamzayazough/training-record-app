import SwiftUI

struct AppHeader: View {
    let title: String
    var subtitle: String? = nil

    var body: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(APP_COLORS.NAVY)
                if let subtitle {
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundStyle(APP_COLORS.MUTED_TEXT)
                }
            }
            Spacer()
            Circle()
                .fill(APP_COLORS.NAVY)
                .frame(width: 42, height: 42)
                .overlay(
                    Image(systemName: "person.fill")
                        .foregroundStyle(.white)
                )
        }
        .padding(.horizontal, APP_LAYOUT.HORIZONTAL_PADDING)
        .padding(.top, 8)
    }
}
