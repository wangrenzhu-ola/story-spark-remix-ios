import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var store: SparkStore
    @State private var selectedTab = 0
    @State private var draftTitle = "Midnight Draft"
    @State private var draftBody = ""

    var body: some View {
        TabView(selection: $selectedTab) {
            TodaySparkView(selectedTab: $selectedTab)
                .tabItem { Label("Today", systemImage: "sparkles") }
                .tag(0)
            RemixLabView(selectedTab: $selectedTab, draftTitle: $draftTitle, draftBody: $draftBody)
                .tabItem { Label("Remix", systemImage: "slider.horizontal.3") }
                .tag(1)
            SparkShelfView(selectedTab: $selectedTab, draftTitle: $draftTitle, draftBody: $draftBody)
                .tabItem { Label("Sprint", systemImage: "books.vertical") }
                .tag(2)
            SettingsView()
                .tabItem { Label("Settings", systemImage: "gearshape") }
                .tag(3)
        }
        .accentColor(.orange)
        .sheet(isPresented: $store.showRevisionBeat) {
            RevisionBeatSheet()
        }
        .onAppear { routePendingCaptureIfNeeded() }
        .onOpenURL { url in
            if store.beginCapture(url: url) { selectedTab = 1 }
        }
    }

    private func routePendingCaptureIfNeeded() {
        if store.consumePendingCapture() { selectedTab = 1 }
    }
}
