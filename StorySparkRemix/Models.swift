import Foundation

enum DraftStatus: String, Codable, CaseIterable, Identifiable {
    case activeSpark = "Active Spark"
    case needsRevision = "Needs Revision"
    case finishedSnippet = "Finished Snippet"

    var id: String { rawValue }
}

struct RemixIngredient: Codable, Equatable, Identifiable, Hashable {
    let id: UUID
    var label: String
    var value: String
    var locked: Bool

    init(id: UUID = UUID(), label: String, value: String, locked: Bool = false) {
        self.id = id
        self.label = label
        self.value = value
        self.locked = locked
    }
}

struct SparkCard: Codable, Equatable, Identifiable {
    var id: UUID
    var title: String
    var seedPhrase: String
    var genre: String
    var characterPressure: String
    var oddObject: String
    var twist: String
    var sentenceConstraint: String
    var createdAt: Date
    var updatedAt: Date
    var visualHue: Double

    init(
        id: UUID = UUID(),
        title: String,
        seedPhrase: String,
        genre: String,
        characterPressure: String,
        oddObject: String,
        twist: String,
        sentenceConstraint: String,
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        visualHue: Double = 0.08
    ) {
        self.id = id
        self.title = title
        self.seedPhrase = seedPhrase
        self.genre = genre
        self.characterPressure = characterPressure
        self.oddObject = oddObject
        self.twist = twist
        self.sentenceConstraint = sentenceConstraint
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.visualHue = visualHue
    }
}

struct RevisionBeat: Codable, Equatable, Identifiable {
    var id: UUID
    var instruction: String
    var completed: Bool

    init(id: UUID = UUID(), instruction: String, completed: Bool = false) {
        self.id = id
        self.instruction = instruction
        self.completed = completed
    }
}

struct MicroDraft: Codable, Equatable, Identifiable {
    var id: UUID
    var title: String
    var spark: SparkCard
    var body: String
    var notes: String
    var status: DraftStatus
    var revisionBeat: RevisionBeat
    var createdAt: Date
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        title: String,
        spark: SparkCard,
        body: String,
        notes: String = "",
        status: DraftStatus = .activeSpark,
        revisionBeat: RevisionBeat,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.spark = spark
        self.body = body
        self.notes = notes
        self.status = status
        self.revisionBeat = revisionBeat
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
