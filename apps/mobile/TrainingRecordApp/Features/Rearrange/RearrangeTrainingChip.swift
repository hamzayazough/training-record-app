import SwiftUI

struct RearrangeTrainingChip: View {
    let label: String
    var muted: Bool = false

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "line.3.horizontal")
                .font(.caption.weight(.semibold))
                .foregroundStyle(APP_COLORS.MUTED_TEXT)
            Text(label)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(APP_COLORS.NAVY)
                .lineLimit(2)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(muted ? APP_COLORS.STATUS_REST : APP_COLORS.SURFACE)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.black.opacity(0.06), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.05), radius: 8, y: 3)
    }
}
