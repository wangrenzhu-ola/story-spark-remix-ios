import Combine
import Foundation

final class SparkStore: ObservableObject {
    @Published private(set) var drafts: [MicroDraft] = []
    @Published var editingSpark: SparkCard?
    @Published var errorMessage: String?
    @Published var showRevisionBeat = false
    @Published var latestRevisionBeat: RevisionBeat?

    private let storageKey = "storySparkRemix.drafts.v1"
    private let remixer = SparkRemixer()
    private let userDefaults: UserDefaults

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
        load()
    }

    var todaySpark: SparkCard {
        remixer.remix(seedPhrase: "A commuter finds a ticket stamped tomorrow.")
    }

    func beginCapture(phrase: String) {
        editingSpark = remixer.remix(seedPhrase: phrase)
    }

    func remix(seedPhrase: String, locked: SparkCard? = nil) {
        editingSpark = remixer.remix(seedPhrase: seedPhrase, locked: locked)
    }

    func updateEditingSpark(_ spark: SparkCard) {
        editingSpark = spark
    }

    @discardableResult
    func saveDraft(title: String, body: String, notes: String = "", status: DraftStatus = .needsRevision) -> Bool {
        let cleanTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanBody = body.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanTitle.isEmpty else {
            errorMessage = "Add a draft title before saving."
            return false
        }
        guard !cleanBody.isEmpty else {
            errorMessage = "Write at least one line before saving this sprint."
            return false
        }
        let spark = editingSpark ?? todaySpark
        var draft = MicroDraft(
            title: cleanTitle,
            spark: spark,
            body: cleanBody,
            notes: notes,
            status: status,
            revisionBeat: RevisionBeat(instruction: "")
        )
        draft.revisionBeat = remixer.revisionBeat(for: draft)
        upsert(draft)
        latestRevisionBeat = draft.revisionBeat
        showRevisionBeat = true
        errorMessage = nil
        return true
    }

    func updateDraft(_ draft: MicroDraft) {
        var changed = draft
        changed.updatedAt = Date()
        upsert(changed)
    }

    func deleteDraft(_ draft: MicroDraft) {
        drafts.removeAll { $0.id == draft.id }
        persist()
    }

    func simulateSaveFailure() {
        errorMessage = "Store was unavailable. Your words stayed in the editor; try Save again."
    }

    func load() {
        guard let data = userDefaults.data(forKey: storageKey) else {
            drafts = []
            return
        }
        drafts = (try? JSONDecoder.appFactory.decode([MicroDraft].self, from: data)) ?? []
    }

    private func upsert(_ draft: MicroDraft) {
        if let index = drafts.firstIndex(where: { $0.id == draft.id }) {
            drafts[index] = draft
        } else {
            drafts.insert(draft, at: 0)
        }
        persist()
    }

    private func persist() {
        guard let data = try? JSONEncoder.appFactory.encode(drafts) else {
            errorMessage = "Could not save locally. Your draft is still on screen."
            return
        }
        userDefaults.set(data, forKey: storageKey)
    }
}

private extension JSONEncoder {
    static var appFactory: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }
}

private extension JSONDecoder {
    static var appFactory: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }
}
