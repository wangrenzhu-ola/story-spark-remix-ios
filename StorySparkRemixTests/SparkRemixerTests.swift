import XCTest
@testable import StorySparkRemix

final class SparkRemixerTests: XCTestCase {
    func testRemixCreatesEditableSparkFields() {
        let spark = SparkRemixer().remix(seedPhrase: "rain inside the last train")
        XCTAssertFalse(spark.title.isEmpty)
        XCTAssertFalse(spark.genre.isEmpty)
        XCTAssertFalse(spark.characterPressure.isEmpty)
        XCTAssertFalse(spark.oddObject.isEmpty)
        XCTAssertFalse(spark.twist.isEmpty)
        XCTAssertFalse(spark.sentenceConstraint.isEmpty)
    }

    func testPersistenceSurvivesStoreReload() {
        let defaults = UserDefaults(suiteName: "StorySparkRemixTests")!
        defaults.removePersistentDomain(forName: "StorySparkRemixTests")
        let store = SparkStore(userDefaults: defaults)
        store.remix(seedPhrase: "a borrowed key hums")
        XCTAssertTrue(store.saveDraft(title: "Key Hum", body: "The key hummed only when Mara lied."))
        let reloaded = SparkStore(userDefaults: defaults)
        XCTAssertEqual(reloaded.drafts.first?.title, "Key Hum")
        XCTAssertEqual(reloaded.drafts.count, 1)
    }


    func testEditingExistingDraftUpdatesInsteadOfDuplicating() {
        let defaults = UserDefaults(suiteName: "StorySparkRemixEditDraftTests")!
        defaults.removePersistentDomain(forName: "StorySparkRemixEditDraftTests")
        let store = SparkStore(userDefaults: defaults)
        store.remix(seedPhrase: "clockwork rain")
        XCTAssertTrue(store.saveDraft(title: "Clock", body: "Rain clicked against the roof."))
        let saved = store.drafts[0]

        store.beginEditingDraft(saved)
        XCTAssertTrue(store.saveDraft(title: "Clock Revised", body: "Rain clicked twice against the roof."))

        XCTAssertEqual(store.drafts.count, 1)
        XCTAssertEqual(store.drafts[0].id, saved.id)
        XCTAssertEqual(store.drafts[0].title, "Clock Revised")
        XCTAssertEqual(store.drafts[0].body, "Rain clicked twice against the roof.")
    }

    func testPendingCaptureHandsOffToEditableSparkOnce() {
        let defaults = UserDefaults(suiteName: "StorySparkRemixPendingCaptureTests")!
        defaults.removePersistentDomain(forName: "StorySparkRemixPendingCaptureTests")
        let store = SparkStore(userDefaults: defaults)

        store.savePendingCapture(phrase: "orange static under the pier")

        XCTAssertTrue(store.consumePendingCapture())
        XCTAssertEqual(store.editingSpark?.seedPhrase, "orange static under the pier")
        XCTAssertFalse(store.consumePendingCapture())
    }

    func testCaptureURLRoutesToEditableSpark() {
        let store = SparkStore(userDefaults: UserDefaults(suiteName: "StorySparkRemixURLCaptureTests")!)
        let url = URL(string: "storyspark://capture?phrase=paper%20moon")!

        XCTAssertTrue(store.beginCapture(url: url))
        XCTAssertEqual(store.editingSpark?.seedPhrase, "paper moon")
        XCTAssertFalse(store.beginCapture(url: URL(string: "https://example.com/capture")!))
    }

    func testPremiumEntitlementReloadsFromLocalDefaults() {
        let defaults = UserDefaults(suiteName: "StorySparkRemixPremiumTests")!
        defaults.removePersistentDomain(forName: "StorySparkRemixPremiumTests")
        defaults.set(true, forKey: SparkPersistenceKeys.premiumUnlocked)

        let premium = PremiumStore(userDefaults: defaults)

        XCTAssertTrue(premium.isPremiumUnlocked)
    }

    func testInvalidSavePreservesErrorState() {
        let defaults = UserDefaults(suiteName: "StorySparkRemixFailureTests")!
        defaults.removePersistentDomain(forName: "StorySparkRemixFailureTests")
        let store = SparkStore(userDefaults: defaults)
        XCTAssertFalse(store.saveDraft(title: "", body: "Still here"))
        XCTAssertEqual(store.drafts.count, 0)
        XCTAssertEqual(store.errorMessage, "Add a draft title before saving.")
    }
}
