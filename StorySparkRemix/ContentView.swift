import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var store: SparkStore
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            TodaySparkView(selectedTab: $selectedTab)
                .tabItem { Label("Today", systemImage: "sparkles") }
                .tag(0)
            RemixLabView(selectedTab: $selectedTab)
                .tabItem { Label("Remix", systemImage: "slider.horizontal.3") }
                .tag(1)
            SparkShelfView(selectedTab: $selectedTab)
                .tabItem { Label("Shelf", systemImage: "books.vertical") }
                .tag(2)
            SettingsView()
                .tabItem { Label("Settings", systemImage: "gearshape") }
                .tag(3)
        }
        .accentColor(.orange)
        .sheet(isPresented: $store.showRevisionBeat) {
            RevisionBeatSheet()
        }
    }
}
