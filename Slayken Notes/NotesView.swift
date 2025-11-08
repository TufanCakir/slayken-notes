import SwiftUI
import StoreKit

@MainActor
struct NotesView: View {
    // MARK: - Environment
    @Environment(\.requestReview) private var requestReview
    @EnvironmentObject private var themeManager: ThemeManager
    @EnvironmentObject private var profileManager: ProfileManager

    // MARK: - Persistent & States
    @AppStorage("launchCount") private var launchCount = 0
    @AppStorage("selectedPencilID") private var selectedPencilID = "pencil_white"

    @State private var notes: [String] = []
    @State private var newNote = ""
    @State private var pencils: [NotesPencil] = []

    // MARK: - Computed Properties
    private var currentTheme: SlaykenTheme? { themeManager.currentTheme }
    private var currentPencil: NotesPencil? { pencils.first(where: { $0.id == selectedPencilID }) }

    // MARK: - Body
    var body: some View {
        ZStack {
            backgroundLayer
                   .onTapGesture {
                       hideKeyboard() // 👈 schließt die Tastatur, wenn man aufs Hintergrund tippt
                   }
            VStack(spacing: 18) {
                headerBar
                newNoteField
                contentSection
            }
            .padding(.top, 20)
            .animation(.easeInOut(duration: 0.25), value: notes)
        }
        .navigationTitle("Notizen")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear(perform: onAppear)
    }
}

// MARK: - Subviews
private extension NotesView {

    // MARK: - Background
    var backgroundLayer: some View {
        Group {
            if let theme = currentTheme {
                theme.fullBackgroundView(blur: 8, opacity: 0.9)
                    .overlay(Color.black.opacity(0.06))
            } else {
                LinearGradient(
                    colors: [.black, .gray.opacity(0.4)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            }
        }
        .ignoresSafeArea()
    }

    // MARK: - Header
    var headerBar: some View {
        HStack(spacing: 14) {
            profileHeader
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 6)
    }

    // MARK: - Profile Header
    var profileHeader: some View {
        HStack(spacing: 6) {
            Image(systemName: "person.circle.fill")
                .font(.system(size: 18))
                .foregroundColor(currentTheme?.accent ?? .blue)

            Text(profileManager.name.isEmpty ? "Willkommen" : profileManager.name)
                .font(.system(size: 17, weight: .medium, design: .rounded))
                .foregroundColor(currentTheme?.accent ?? .blue)
                .lineLimit(1)
                .accessibilityLabel("Profil: \(profileManager.name)")
        }
    }

    var dynamicFieldBackground: some View {
        if let bg = currentPencil?.textFieldBackground {
            switch bg.type {
            case "linearGradient":
                return AnyView(
                    LinearGradient(
                        colors: bg.colors.map(Color.init(hex:)),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            default:
                return AnyView(
                    Color(hex: bg.colors.first ?? "#000000")
                )
            }
        } else {
            return AnyView(Color.black.opacity(0.3))
        }
    }

    // MARK: - Input Field
    var newNoteField: some View {
        HStack(spacing: 10) {
            ZStack(alignment: .leading) {
                // Placeholder
                if newNote.isEmpty {
                    Text("Neue Notiz hinzufügen …")
                        .foregroundStyle(.secondary)
                        .padding(.vertical, 12)
                        .padding(.horizontal, 16)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                // Eingabe + Gradient
                TextField("", text: $newNote, axis: .vertical)
                    .textFieldStyle(.plain)
                    .padding(.vertical, 12)
                    .padding(.horizontal, 16)
                    .multilineTextAlignment(.leading) // ← sorgt für linke Ausrichtung
                    .frame(maxWidth: .infinity, alignment: .leading) // ← sorgt für oberen Textfluss
                    .background(dynamicFieldBackground)
                    .cornerRadius(12)
                    .font(.system(size: 17, weight: .medium, design: .rounded))
                    .foregroundColor(.clear) // Text unsichtbar
                    .overlay(
                        LinearGradient(
                            colors: currentPencil?.pencilColor.map(Color.init(hex:)) ?? [.white],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                        .mask(
                            Text(newNote.isEmpty ? " " : newNote)
                                .font(.system(size: 17, weight: .medium, design: .rounded))
                                .padding(.vertical, 12)
                                .padding(.horizontal, 16)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .multilineTextAlignment(.leading)
                        )
                        .allowsHitTesting(false)
                    )
            }

            Button(action: addNote) {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 28))
                    .foregroundStyle(
                        LinearGradient(
                            colors: currentPencil?.pencilColor.map(Color.init(hex:)) ?? [.white],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .shadow(
                        color: Color(hex: currentPencil?.pencilColor.first ?? "#FFFFFF").opacity(0.5),
                        radius: 6
                    )
            }
            .disabled(newNote.trimmingCharacters(in: .whitespaces).isEmpty)
            .opacity(newNote.trimmingCharacters(in: .whitespaces).isEmpty ? 0.5 : 1)
        }
        .padding(.horizontal, 20)
    }

    // MARK: - Notes List
    var contentSection: some View {
        GeometryReader { geo in
            Group {
                if notes.isEmpty {
                    emptyState
                } else {
                    ScrollView {
                        LazyVStack(spacing: 14) {
                            ForEach(notes.indices, id: \.self) { index in
                                noteCard(note: notes[index], index: index)
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 30)
                    }
                    .scrollDismissesKeyboard(.interactively) // 🧠 NEU: iOS 16+ → wie Apple Notes
                }
            }
            .frame(width: geo.size.width, height: geo.size.height)
        }
    }

    // MARK: - Empty State
    var emptyState: some View {
        VStack(spacing: 8) {
            Image(systemName: "square.and.pencil")
                .font(.largeTitle)
                .foregroundColor(.gray)
            Text("Noch keine Notizen")
                .font(.subheadline)
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Dynamic Card Background (kompatibel mit .fill)
    func dynamicCardBackground() -> AnyShapeStyle {
        if let bg = currentPencil?.textFieldBackground {
            switch bg.type {
            case "linearGradient":
                return AnyShapeStyle(
                    LinearGradient(
                        colors: bg.colors.map(Color.init(hex:)),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            default:
                return AnyShapeStyle(
                    Color(hex: bg.colors.first ?? "#000000")
                )
            }
        } else {
            return AnyShapeStyle(Color.black.opacity(0.2))
        }
    }



    // MARK: - Note Card
    func noteCard(note: String, index: Int) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            gradientText(note)

            HStack {
                Spacer()
                Button(role: .destructive, action: { deleteNote(at: index) }) {
                    Label("Löschen", systemImage: "trash")
                        .font(.caption)
                        .foregroundColor(.red)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(dynamicCardBackground()) // ← verwendet jetzt dein Pencil-Background
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(currentTheme?.accent.opacity(0.25) ?? .gray, lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.2), radius: 4, y: 2)
        )
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }


    // MARK: - Gradient Text
    func gradientText(_ text: String) -> some View {
        Text(text)
            .font(.body)
            .multilineTextAlignment(.leading)
            .overlay(
                LinearGradient(
                    colors: currentPencil?.pencilColor.map(Color.init(hex:)) ?? [.white],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .mask(
                    Text(text)
                        .font(.body)
                        .multilineTextAlignment(.leading)
                )
            )
    }
}

// MARK: - Logic
private extension NotesView {

    func addNote() {
        let trimmed = newNote.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
            notes.insert(trimmed, at: 0)
            newNote = ""
            saveNotes()
            Haptic.selection()
        }
    }

    func deleteNote(at index: Int) {
        withAnimation(.easeInOut(duration: 0.25)) {
            notes.remove(at: index)
            saveNotes()
            Haptic.selection()
        }
    }

    func saveNotes() {
        UserDefaults.standard.set(notes, forKey: "savedNotes")
    }

    func loadNotes() {
        notes = UserDefaults.standard.array(forKey: "savedNotes") as? [String] ?? []
    }

    func handleAppLaunch() {
        launchCount += 1
        if launchCount % 5 == 0 { requestReview() }
    }

    func onAppear() {
        pencils = PencilDataLoader.loadAll()
        loadNotes()
        handleAppLaunch()
    }
}

// MARK: - Preview
#Preview {
    NotesView()
        .environmentObject(ThemeManager())
        .environmentObject(ProfileManager())
        .preferredColorScheme(.dark)
}

#if canImport(UIKit)
extension View {
    func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder),
                                        to: nil, from: nil, for: nil)
    }
}
#endif
