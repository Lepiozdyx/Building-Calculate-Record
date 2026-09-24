import SwiftUI

struct MainTabView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        @Bindable var appState = appState
        TabView(selection: $appState.selectedTab) {
            HomeView()
                .tabItem { Label("Home", systemImage: "house.fill") }
                .tag(0)
            CalculatorContainerView()
                .tabItem { Label("Calculator", systemImage: "square.grid.2x2.fill") }
                .tag(1)
            HistoryView()
                .tabItem { Label("History", systemImage: "clock.fill") }
                .tag(2)
            TipsView()
                .tabItem { Label("Tips", systemImage: "sparkles") }
                .tag(3)
            ProfileView()
                .tabItem { Label("Profile", systemImage: "person.fill") }
                .tag(4)
        }
        .tint(AppTheme.yellow)
    }
}

struct CalculatorContainerView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        @Bindable var appState = appState
        NavigationStack {
            CalculatorView()
                .navigationDestination(isPresented: $appState.showResultFromCalculator) {
                    if let draft = appState.pendingResultDraft {
                        ResultView(draft: draft, isNew: true)
                    }
                }
        }
    }
}
