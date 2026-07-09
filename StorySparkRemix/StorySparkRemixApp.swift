import SwiftUI

@main
struct StorySparkRemixApp: App {
    @StateObject private var store: SparkStore
    @StateObject private var premiumStore: PremiumStore

    init() {
        if ProcessInfo.processInfo.arguments.contains("-ui-testing"),
           let bundleID = Bundle.main.bundleIdentifier {
            UserDefaults.standard.removePersistentDomain(forName: bundleID)
        }
        _store = StateObject(wrappedValue: SparkStore())
        _premiumStore = StateObject(wrappedValue: PremiumStore())
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(store)
                .environmentObject(premiumStore)
        }
    }
}
