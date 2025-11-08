import SwiftUI
import StoreKit

// MARK: - Darstellungsauswahl
enum AppAppearance: String, CaseIterable, Identifiable {
    case system = "System"
    case light = "Hell"
    case dark = "Dunkel"

    var id: String { rawValue }

    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light:  return .light
        case .dark:   return .dark
        }
    }

    var icon: String {
        switch self {
        case .system: return "circle.lefthalf.fill"
        case .light:  return "sun.max.fill"
        case .dark:   return "moon.fill"
        }
    }
}

// MARK: - Einstellungen
struct SettingsView: View {
    // MARK: - Environments
    @Environment(\.requestReview) private var requestReview

    // MARK: - AppStorage
    @AppStorage("appAppearance") private var appearanceRaw = AppAppearance.system.rawValue

    // MARK: - UI State
    @State private var showResetConfirmation = false
    @State private var showResetSuccess = false
    @State private var isResetting = false

    @Environment(\.horizontalSizeClass) private var sizeClass

    // MARK: - Computed Properties
    private var appearance: AppAppearance {
        get { AppAppearance(rawValue: appearanceRaw) ?? .system }
        set { appearanceRaw = newValue.rawValue }
    }

    // MARK: - View
    var body: some View {
        NavigationStack {
            List {
                // MARK: - Darstellung
                Section {
                    Picker("App-Darstellung", selection: $appearanceRaw) {
                        ForEach(AppAppearance.allCases) { mode in
                            Label(mode.rawValue, systemImage: mode.icon)
                                .font(.system(size: fontSizeBase))
                                .tag(mode.rawValue)
                        }
                    }
                    .pickerStyle(.inline)
                    .accessibilityLabel("App-Darstellung ändern")
                } header: {
                    sectionHeader("Darstellung")
                }

            

                // MARK: - Feedback
                Section {
                    Button {
                        requestReview()
                        haptic(.light)
                    } label: {
                        Label("App bewerten (In-App)", systemImage: "star.fill")
                            .font(.system(size: fontSizeBase))
                            .foregroundColor(.yellow)
                            .padding(.vertical, buttonPadding)
                    }

                    Button {
                        openAppStoreReviewPage()
                        haptic(.medium)
                    } label: {
                        Label("Im App Store bewerten", systemImage: "link")
                            .font(.system(size: fontSizeBase))
                            .foregroundColor(.blue)
                            .padding(.vertical, buttonPadding)
                    }
                } header: {
                    sectionHeader("Feedback")
                }
            }
            .scrollContentBackground(.hidden)
            .background(
                LinearGradient(colors: [.black.opacity(0.1), .clear],
                               startPoint: .top,
                               endPoint: .bottom)
                    .ignoresSafeArea()
            )
            .navigationTitle("Einstellungen")
            .navigationBarTitleDisplayMode(.inline)
            .preferredColorScheme(appearance.colorScheme)
            .overlay(loadingOverlay)
        }
    }


    private func openAppStoreReviewPage() {
        let appID = "6755046316"
        if let url = URL(string: "https://apps.apple.com/app/id\(appID)?action=write-review") {
            UIApplication.shared.open(url)
        }
    }

    // MARK: - UI Komponenten
    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.system(size: fontSizeHeadline, weight: .semibold))
            .foregroundStyle(.secondary)
    }



    private var loadingOverlay: some View {
        Group {
            if isResetting {
                ZStack {
                    Color.black.opacity(0.4).ignoresSafeArea()
                    ProgressView("Wird zurückgesetzt…")
                        .progressViewStyle(.circular)
                        .tint(.white)
                        .foregroundColor(.white)
                        .font(.headline)
                        .padding()
                        .background(.ultraThinMaterial)
                        .cornerRadius(12)
                        .shadow(radius: 8)
                }
                .transition(.opacity)
            }
        }
    }

    // MARK: - Haptisches Feedback
    private func haptic(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
        UIImpactFeedbackGenerator(style: style).impactOccurred()
    }
}

// MARK: - Dynamische Größen
private extension SettingsView {
    var fontSizeHeadline: CGFloat { sizeClass == .regular ? 22 : 18 }
    var fontSizeBase: CGFloat { sizeClass == .regular ? 18 : 16 }
    var buttonPadding: CGFloat { sizeClass == .regular ? 8 : 4 }
}

#Preview {
    SettingsView()
}
