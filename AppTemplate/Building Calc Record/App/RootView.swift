import SwiftUI

struct RootView: View {
    @Environment(SettingsStore.self) private var settings
    @State private var appState = AppState()

    var body: some View {
        Group {
            if settings.hasCompletedOnboarding {
                MainTabView()
            } else {
                OnboardingView()
            }
        }
        .environment(appState)
    }
}
