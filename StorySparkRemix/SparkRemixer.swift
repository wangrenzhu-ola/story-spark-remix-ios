import Foundation

struct SparkRemixer {
    private let genres = ["Noir", "Cozy Speculative", "Kitchen Realism", "Tiny Myth", "Campus Mystery"]
    private let pressures = ["owes a promise", "must hide a lucky lie", "cannot miss the last train", "needs one brave sentence", "is protecting a secret recipe"]
    private let objects = ["blue matchbox", "paper moon", "borrowed key", "cracked teacup", "ticket stamped tomorrow"]
    private let twists = ["the helper caused the problem", "the object answers back", "the safest choice costs the most", "the ending image changes meaning", "the witness is unreliable"]
    private let constraints = ["Open with a sound.", "Use one sentence under seven words.", "End on a concrete image.", "Avoid the word suddenly.", "Make the last line a question."]

    func remix(seedPhrase: String, locked: SparkCard? = nil) -> SparkCard {
        let phrase = seedPhrase.trimmingCharacters(in: .whitespacesAndNewlines)
        let score = max(phrase.count, 1)
        let title = phrase.isEmpty ? "Untitled Spark" : String(phrase.prefix(44))
        return SparkCard(
            title: title,
            seedPhrase: phrase,
            genre: locked?.genre ?? pick(genres, score),
            characterPressure: locked?.characterPressure ?? pick(pressures, score + 3),
            oddObject: locked?.oddObject ?? pick(objects, score + 7),
            twist: locked?.twist ?? pick(twists, score + 11),
            sentenceConstraint: locked?.sentenceConstraint ?? pick(constraints, score + 17),
            visualHue: Double((score * 29) % 360) / 360.0
        )
    }

    func revisionBeat(for draft: MicroDraft) -> RevisionBeat {
        let choices = [
            "Tighten the point of view around the hardest choice.",
            "Raise the cost of keeping the odd object.",
            "Change the final image so it echoes the first line.",
            "Cut one explanation and let the action carry it."
        ]
        return RevisionBeat(instruction: pick(choices, draft.body.count + draft.title.count))
    }

    private func pick(_ values: [String], _ seed: Int) -> String {
        values[abs(seed) % values.count]
    }
}
