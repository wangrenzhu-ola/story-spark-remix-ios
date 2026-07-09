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

    func testInvalidSavePreservesErrorState() {
        let defaults = UserDefaults(suiteName: "StorySparkRemixFailureTests")!
        defaults.removePersistentDomain(forName: "StorySparkRemixFailureTests")
        let store = SparkStore(userDefaults: defaults)
        XCTAssertFalse(store.saveDraft(title: "", body: "Still here"))
        XCTAssertEqual(store.drafts.count, 0)
        XCTAssertEqual(store.errorMessage, "Add a draft title before saving.")
    }
}
