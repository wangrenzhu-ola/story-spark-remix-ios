import Foundation

#if canImport(AppIntents)
import AppIntents

@available(iOS 16.0, *)
struct CaptureStorySparkIntent: AppIntent {
    static var title: LocalizedStringResource = "Capture Story Spark"
    static var description = IntentDescription("Capture one dictated idea and open Story Spark Remix with an editable SparkCard draft.")
    static var openAppWhenRun: Bool = true

    @Parameter(title: "Idea")
    var idea: String

    static var parameterSummary: some ParameterSummary {
        Summary("Capture \(\.$idea)")
    }

    func perform() async throws -> some IntentResult {
        UserDefaults.standard.set(idea.trimmingCharacters(in: .whitespacesAndNewlines), forKey: SparkPersistenceKeys.pendingCapture)
        return .result(dialog: "Opening Story Spark Remix with your captured idea ready for manual review: \(idea)")
    }
}
#endif
