import SwiftUI

@main
struct StorySparkRemixApp: App {
    @StateObject private var store = SparkStore()
    @StateObject private var premiumStore = PremiumStore()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(store)
                .environmentObject(premiumStore)
        }
    }
}
