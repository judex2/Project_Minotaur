import SwiftUI

enum RootTab: String, CaseIterable, Hashable { case home, explore, profile }

struct RootView: View {
    @State private var state = AppState()
    @State private var tab: RootTab = .home
    @State private var baselineTarget: Labyrinth?
    @AppStorage("appearance") private var appearance = "System"
    @AppStorage("completedOrientation") private var completedOrientation = false
    @State private var showOrientation = false

    var body: some View {
        TabView(selection: $tab) {
            HomeView(onExplore: { tab = .explore }).tabItem { Label("Home", systemImage: "house") }.tag(RootTab.home)
            ExploreView().tabItem { Label("Explore", systemImage: "safari") }.tag(RootTab.explore)
            ProfileView().tabItem { Label("Profile", systemImage: "person.crop.circle") }.tag(RootTab.profile)
        }
        .environment(state)
        .defaultAppStorage(ProcessInfo.processInfo.environment["MINOTAUR_TEST_STATE"].flatMap { UserDefaults(suiteName: $0) } ?? .standard)
        .tint(Ink.signalSoft)
        .preferredColorScheme(appearance == "Light" ? .light : appearance == "Dark" ? .dark : nil)
        .onAppear { showOrientation = !completedOrientation }
        .onChange(of: state.baselinePrompt) { _, value in baselineTarget = value }
        .sheet(item: $baselineTarget, onDismiss: { state.baselinePrompt = nil }) { program in
            BaselineCaptureView(labyrinth: program).environment(state).presentationBackground(Ink.canvas)
        }
        .sheet(isPresented: $showOrientation) {
            OrientationView {
                completedOrientation = true
                showOrientation = false
            }.environment(state).interactiveDismissDisabled()
        }
    }
}
