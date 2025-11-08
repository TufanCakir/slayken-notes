import SwiftUI

struct PencilCircleView: View {
    let pencil: NotesPencil
    let isSelected: Bool

    var body: some View {
        ZStack {
            switch pencil.type {
            case "linearGradient":
                LinearGradient(
                    colors: pencil.pencilColor.map { Color(hex: $0) },
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .clipShape(Circle())

            case "meshGradient":
                RadialGradient(
                    colors: pencil.pencilColor.map { Color(hex: $0) },
                    center: .center,
                    startRadius: 4,
                    endRadius: 20
                )
                .clipShape(Circle())

            default:
                Circle().fill(Color(hex: pencil.pencilColor.first ?? "#FFFFFF"))
            }

            if isSelected {
                Circle()
                    .strokeBorder(Color.white, lineWidth: 2.5)
                    .frame(width: 26, height: 26)
                    .shadow(color: .white.opacity(0.4), radius: 4)
            }
        }
        .frame(width: 22, height: 22)
        .shadow(color: Color(hex: pencil.pencilColor.first ?? "#FFFFFF").opacity(0.4), radius: 3, x: 0, y: 2)
        .animation(.spring(response: 0.35, dampingFraction: 0.8), value: isSelected)
    }
}
