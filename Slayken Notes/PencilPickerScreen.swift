import SwiftUI

struct PencilPickerScreen: View {
    @AppStorage("selectedPencilID") private var selectedPencilID = "pencil_white"
    @State private var selectedCategory: String = "All"
    @State private var pencils: [NotesPencil] = PencilDataLoader.loadAll()

    // MARK: - Grid Layout
    private let columns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]

    // MARK: - Filter & Kategorien
    private var filteredPencils: [NotesPencil] {
        selectedCategory == "All"
        ? pencils
        : pencils.filter { $0.category == selectedCategory }
    }

    private var categories: [String] {
        let base = ["All"]
        let pencilCats = pencils.compactMap { $0.category }
            .removingDuplicates()
            .sorted()
        return base + pencilCats
    }

    private var currentPencil: NotesPencil? {
        pencils.first(where: { $0.id == selectedPencilID })
    }

    // MARK: - Body
    var body: some View {
        ZStack {
            // Hintergrund
            LinearGradient(
                colors: [Color.black, Color.gray.opacity(0.35)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                // 🧩 Live-Vorschau (aktueller Pencil)
                if let pencil = currentPencil {
                    PencilPreviewCard(pencil: pencil)
                        .padding(.horizontal, 20)
                        .padding(.top, 16)
                        .transition(.opacity)
                        .animation(.easeInOut(duration: 0.25), value: selectedPencilID)
                }

                // MARK: - Kategorieauswahl
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(categories, id: \.self) { category in
                            categoryButton(for: category)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                }
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .padding(.horizontal, 16)
                .padding(.top, 12)

                // MARK: - Pencil Grid
                ScrollView {
                    LazyVGrid(columns: columns, spacing: 20) {
                        ForEach(filteredPencils) { pencil in
                            pencilCard(pencil: pencil, isSelected: pencil.id == selectedPencilID)
                                .onTapGesture {
                                    withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                                        selectedPencilID = pencil.id
                                        Haptic.selection()
                                    }
                                }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 16)
                    .padding(.bottom, 60)
                }
            }
            .navigationTitle("Stiftfarben")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    // MARK: - Kategorie Button
    private func categoryButton(for category: String) -> some View {
        let isSelected = category == selectedCategory
        return Button {
            withAnimation(.spring(response: 0.25, dampingFraction: 0.85)) {
                selectedCategory = category
                Haptic.selection()
            }
        } label: {
            HStack(spacing: 6) {
                if category != "All",
                   let icon = pencils.first(where: { $0.category == category })?.categoryIcon {
                    Image(systemName: icon)
                        .font(.caption)
                }
                Text(category.capitalized)
                    .font(.footnote.weight(.semibold))
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.accentColor.opacity(0.25)
                                     : Color.secondary.opacity(0.1))
            )
            .foregroundColor(isSelected ? .primary : .secondary)
            .animation(.easeInOut(duration: 0.25), value: isSelected)
        }
    }

    // MARK: - Pencil Card (Grid)
    private func pencilCard(pencil: NotesPencil, isSelected: Bool) -> some View {
        VStack(spacing: 8) {
            ZStack {
                // 🎨 Hintergrund
                if pencil.pencilColor.count > 1 {
                    LinearGradient(
                        colors: pencil.pencilColor.map { Color(hex: $0) },
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                } else {
                    Color(hex: pencil.pencilColor.first ?? "#FFFFFF")
                }

                // ✍️ Overlay Info
                VStack(spacing: 6) {
                    HStack(spacing: 4) {
                        if let icon = pencil.categoryIcon {
                            Image(systemName: icon)
                                .font(.caption)
                                .foregroundColor(Color(hex: pencil.categoryIconColor ?? "#FFFFFF"))
                        }
                        Text(pencil.category.uppercased())
                            .font(.caption2.bold())
                            .foregroundColor(Color(hex: pencil.categoryIconColor ?? "#FFFFFF"))
                    }

                    Text(pencil.title)
                        .font(.footnote.weight(.semibold))
                        .foregroundColor(.white)
                        .shadow(color: .black.opacity(0.6), radius: 1, y: 1)
                }
                .padding(10)
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .frame(height: 130)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? Color(hex: pencil.pencilColor.first ?? "#FFFFFF") : .clear, lineWidth: 3)
                    .shadow(color: Color(hex: pencil.pencilColor.first ?? "#FFFFFF")
                        .opacity(isSelected ? 0.45 : 0), radius: 6)
            )
            .scaleEffect(isSelected ? 1.05 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.85), value: isSelected)

            Text(pencil.title)
                .font(.caption)
                .fontWeight(isSelected ? .semibold : .regular)
                .foregroundColor(isSelected
                                 ? Color(hex: pencil.pencilColor.first ?? "#FFFFFF")
                                 : .secondary)
                .lineLimit(1)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Live-Vorschau-Komponente (Mini PencilPreviewCard)
struct PencilPreviewCard: View {
    let pencil: NotesPencil

    private var backgroundStyle: LinearGradient {
        if let bg = pencil.textFieldBackground, bg.type == "linearGradient" {
            return LinearGradient(
                colors: bg.colors.map(Color.init(hex:)),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        } else {
            let color = Color(hex: pencil.textFieldBackground?.colors.first ?? "#111111")
            return LinearGradient(
                colors: [color.opacity(0.9), color.opacity(0.7)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16)
                .fill(backgroundStyle)
                .shadow(color: .black.opacity(0.25), radius: 5, y: 2)

            VStack(spacing: 10) {
                // MARK: Titel in Stiftfarbe
                Text(pencil.title)
                    .font(.headline.weight(.semibold))
                    .multilineTextAlignment(.center)
                    .overlay(
                        LinearGradient(
                            colors: pencil.pencilColor.map(Color.init(hex:)),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                        .mask(
                            Text(pencil.title)
                                .font(.headline.weight(.semibold))
                        )
                    )

                // MARK: Vorschau-Text mit Gradient
                Text("The quick brown fox jumps over the lazy dog.")
                    .font(.subheadline)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 8)
                    .overlay(
                        LinearGradient(
                            colors: pencil.pencilColor.map(Color.init(hex:)),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                        .mask(
                            Text("The quick brown fox jumps over the lazy dog.")
                                .font(.subheadline)
                                .multilineTextAlignment(.center)
                        )
                    )
            }
            .padding(14)
        }
        .frame(height: 120)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
    }
}

#Preview {
    NavigationStack {
        PencilPickerScreen()
            .preferredColorScheme(.dark)
    }
}
