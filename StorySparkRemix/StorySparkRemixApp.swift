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
                .onOpenURL { url in
                    guard url.scheme == "storyspark", url.host == "capture" else { return }
                    let phrase = URLComponents(url: url, resolvingAgainstBaseURL: false)?
                        .queryItems?
                        .first(where: { $0.name == "phrase" })?
                        .value ?? ""
                    store.beginCapture(phrase: phrase)
                }
        }
    }
}
