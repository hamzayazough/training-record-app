import SwiftUI

struct StatusDot: View {
    let status: PERFORMANCE_STATUS
    var size: CGFloat = 10

    var body: some View {
        Circle()
            .fill(status.color)
            .frame(width: size, height: size)
    }
}
