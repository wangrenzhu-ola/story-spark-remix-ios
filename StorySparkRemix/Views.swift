import SwiftUI

struct TodaySparkView: View {
    @EnvironmentObject private var store: SparkStore
    @Binding var selectedTab: Int

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    InkSparkHero(spark: store.todaySpark)
                    Button("Remix This Spark") {
                        store.updateEditingSpark(store.todaySpark)
                        selectedTab = 1
                    }
                    .buttonStyle(PrimarySparkButtonStyle())
                    RecentDraftsSection(selectedTab: $selectedTab)
                }
                .padding()
            }
            .background(Color.midnightPaper.ignoresSafeArea())
            .navigationTitle("Story Spark Remix")
        }
    }
}

struct RemixLabView: View {
    @EnvironmentObject private var store: SparkStore
    @Binding var selectedTab: Int
    @State private var seedPhrase = ""

    var body: some View {
        NavigationView {
            VStack(spacing: 16) {
                TextField("Type one idea or paste a dictated phrase", text: $seedPhrase)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .accessibilityLabel("Manual spark phrase")
                Button("Build Editable SparkCard") { buildSpark() }
                    .buttonStyle(PrimarySparkButtonStyle())
                if let spark = store.editingSpark {
                    SparkCardEditor(spark: spark) { changed in
                        store.updateEditingSpark(changed)
                    }
                    Button("Start 12-Minute Sprint") { selectedTab = 2 }
                        .buttonStyle(PrimarySparkButtonStyle())
                } else {
                    EmptyNotebookView(title: "No SparkCard yet", message: "Capture a phrase or remix today’s starter to begin.")
                }
                Spacer(minLength: 0)
            }
            .padding()
            .background(Color.midnightPaper.ignoresSafeArea())
            .navigationTitle("Remix Lab")
            .toolbar { Button("Use Starter") { store.remix(seedPhrase: "A key arrives with tomorrow’s date.") } }
        }
    }

    private func buildSpark() {
        store.remix(seedPhrase: seedPhrase)
    }
}

struct SparkShelfView: View {
    @EnvironmentObject private var store: SparkStore
    @Binding var selectedTab: Int
    @State private var draftBody = ""
    @State private var draftTitle = "Midnight Draft"
    @State private var deleteCandidate: MicroDraft?

    var body: some View {
        NavigationView {
            List {
                SprintWriterSection(draftTitle: $draftTitle, draftBody: $draftBody)
                if store.drafts.isEmpty {
                    EmptyNotebookView(title: "Your shelf is blank", message: "Create the first SparkCard, sprint for twelve minutes, and save a micro-fiction draft.")
                        .listRowBackground(Color.clear)
                } else {
                    ForEach(DraftStatus.allCases) { status in
                        Section(status.rawValue) {
                            ForEach(store.drafts.filter { $0.status == status }) { draft in
                                DraftPulseCard(draft: draft) {
                                    store.updateEditingSpark(draft.spark)
                                    draftTitle = draft.title
                                    draftBody = draft.body
                                } onDelete: {
                                    deleteCandidate = draft
                                }
                            }
                        }
                    }
                }
            }
            .listStyle(InsetGroupedListStyle())
            .navigationTitle("Spark Shelf")
            .toolbar { Button("Remix") { selectedTab = 1 } }
            .alert(item: $deleteCandidate) { draft in
                Alert(
                    title: Text("Delete \"\(draft.title)\"?"),
                    message: Text("This removes the saved microdraft from this device."),
                    primaryButton: .destructive(Text("Delete")) { store.deleteDraft(draft) },
                    secondaryButton: .cancel()
                )
            }
        }
    }
}

struct SprintWriterSection: View {
    @EnvironmentObject private var store: SparkStore
    @Binding var draftTitle: String
    @Binding var draftBody: String
    @State private var minutesRemaining = 12

    var body: some View {
        Section {
            VStack(alignment: .leading, spacing: 12) {
                Text("12-Minute Sprint")
                    .font(.headline)
                if let spark = store.editingSpark {
                    SparkSummary(spark: spark)
                }
                TextField("Draft title", text: $draftTitle)
                    .accessibilityLabel("Microdraft title")
                TextEditor(text: $draftBody)
                    .frame(minHeight: 180)
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.orange.opacity(0.25)))
                    .accessibilityLabel("Microdraft body")
                if let error = store.errorMessage {
                    Text(error)
                        .foregroundColor(.red)
                        .accessibilityLabel("Save error: \(error)")
                }
                HStack {
                    Label("\(minutesRemaining) minutes", systemImage: "timer")
                    Spacer()
                    Button("Simulate Save Failure") { store.simulateSaveFailure() }
                    Button("Save Draft") { _ = store.saveDraft(title: draftTitle, body: draftBody) }
                        .buttonStyle(.borderedProminent)
                }
            }
        }
    }
}

struct RevisionBeatSheet: View {
    @EnvironmentObject private var store: SparkStore
    @Environment(\.presentationMode) private var presentationMode
    @State private var beatText = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("Revision Beat")
                .font(.largeTitle.bold())
            TextEditor(text: $beatText)
                .frame(minHeight: 120)
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.orange.opacity(0.35)))
                .onAppear { beatText = store.latestRevisionBeat?.instruction ?? "Tighten the point of view before the next sprint." }
                .accessibilityLabel("Editable revision beat")
            Button("Save for Next Sprint") { presentationMode.wrappedValue.dismiss() }
                .buttonStyle(PrimarySparkButtonStyle())
            Button("Skip This Beat") { presentationMode.wrappedValue.dismiss() }
        }
        .padding()
    }
}

struct SettingsView: View {
    @EnvironmentObject private var premiumStore: PremiumStore

    var body: some View {
        NavigationView {
            Form {
                Section("Privacy") {
                    Text("Your ideas, SparkCards, drafts, and revision beats stay on this device unless you choose to export them in a future version.")
                    Text("Starter spark decks are bundled local examples and are editable before use.")
                    Text("Locale: English (United States).")
                }
                Section("Premium") {
                    Text("Premium will unlock expanded decks, unlimited saved sparks, and advanced style packs. The core writing sprint stays free.")
                    if let message = premiumStore.unavailableMessage { Text(message).foregroundColor(.secondary) }
                    Button("Check Premium") { Task { await premiumStore.loadProducts() } }
                    Button("Restore Purchases") { Task { await premiumStore.restorePurchases() } }
                }
            }
            .navigationTitle("Settings")
        }
    }
}

private struct RecentDraftsSection: View {
    @EnvironmentObject private var store: SparkStore
    @Binding var selectedTab: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recent Draft")
                .font(.headline)
                .foregroundColor(.paperCream)
            if let draft = store.drafts.first {
                DraftPulseCard(draft: draft) { selectedTab = 2 } onDelete: {}
            } else {
                EmptyNotebookView(title: "No saved draft yet", message: "A twelve-minute sprint will turn this starter spark into your first saved scene.")
            }
        }
    }
}

private struct InkSparkHero: View {
    let spark: SparkCard

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            ZStack(alignment: .bottomLeading) {
                RoundedRectangle(cornerRadius: 28)
                    .fill(LinearGradient(colors: [.black, .deepViolet, .emberGold.opacity(0.75)], startPoint: .topLeading, endPoint: .bottomTrailing))
                Circle().fill(Color.emberGold.opacity(0.28)).blur(radius: 18).offset(x: 90, y: -30)
                VStack(alignment: .leading, spacing: 8) {
                    Text("Today’s Spark")
                        .font(.caption.weight(.semibold))
                        .foregroundColor(.emberGold)
                    Text(spark.title)
                        .font(.largeTitle.bold())
                        .foregroundColor(.paperCream)
                    SparkSummary(spark: spark)
                }
                .padding()
            }
            .frame(minHeight: 240)
            .accessibilityLabel("Ink spark hero card for today's starter prompt")
        }
    }
}

private struct SparkCardEditor: View {
    var spark: SparkCard
    var onChange: (SparkCard) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            EditableChip(label: "Genre", value: spark.genre) { update(genre: $0) }
            EditableChip(label: "Pressure", value: spark.characterPressure) { update(pressure: $0) }
            EditableChip(label: "Odd Object", value: spark.oddObject) { update(object: $0) }
            EditableChip(label: "Twist", value: spark.twist) { update(twist: $0) }
            EditableChip(label: "Constraint", value: spark.sentenceConstraint) { update(constraint: $0) }
        }
        .padding()
        .background(Color.paperCream)
        .cornerRadius(22)
    }

    private func update(genre: String? = nil, pressure: String? = nil, object: String? = nil, twist: String? = nil, constraint: String? = nil) {
        var changed = spark
        if let genre = genre { changed.genre = genre }
        if let pressure = pressure { changed.characterPressure = pressure }
        if let object = object { changed.oddObject = object }
        if let twist = twist { changed.twist = twist }
        if let constraint = constraint { changed.sentenceConstraint = constraint }
        onChange(changed)
    }
}

private struct EditableChip: View {
    let label: String
    let value: String
    let onChange: (String) -> Void
    @State private var draftValue: String = ""

    var body: some View {
        VStack(alignment: .leading) {
            Text(label).font(.caption.bold()).foregroundColor(.secondary)
            TextField(value, text: $draftValue, onCommit: { onChange(draftValue.isEmpty ? value : draftValue) })
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .accessibilityLabel("\(label) chip, \(value)")
        }
    }
}

private struct SparkSummary: View {
    let spark: SparkCard

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Label(spark.genre, systemImage: "die.face.5")
            Label(spark.characterPressure, systemImage: "person.crop.circle.badge.exclamationmark")
            Label(spark.oddObject, systemImage: "shippingbox")
            Label(spark.twist, systemImage: "arrow.triangle.2.circlepath")
            Label(spark.sentenceConstraint, systemImage: "text.quote")
        }
        .font(.subheadline)
        .foregroundColor(.paperCream)
    }
}

private struct DraftPulseCard: View {
    let draft: MicroDraft
    let onEdit: () -> Void
    let onDelete: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(draft.title).font(.headline)
                Spacer()
                Text(draft.status.rawValue).font(.caption).padding(6).background(Color.emberGold.opacity(0.25)).cornerRadius(8)
            }
            Text(draft.body).lineLimit(3)
            Text("Next: \(draft.revisionBeat.instruction)").font(.caption).foregroundColor(.secondary)
            HStack {
                Button("Edit") { onEdit() }
                Spacer()
                Button("Delete", role: .destructive) { onDelete() }
            }
        }
        .padding(.vertical, 8)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Draft pulse card, \(draft.title), \(draft.status.rawValue)")
    }
}

private struct EmptyNotebookView: View {
    let title: String
    let message: String

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "book.closed")
                .font(.system(size: 44))
                .foregroundColor(.emberGold)
            Text(title).font(.headline)
            Text(message).font(.subheadline).multilineTextAlignment(.center).foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(28)
        .background(Color.paperCream)
        .cornerRadius(24)
        .accessibilityLabel("Empty notebook illustration, \(title)")
    }
}

struct PrimarySparkButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .frame(maxWidth: .infinity)
            .padding()
            .background(configuration.isPressed ? Color.emberGold.opacity(0.75) : Color.emberGold)
            .foregroundColor(.black)
            .cornerRadius(16)
    }
}

extension Color {
    static let midnightPaper = Color(red: 0.06, green: 0.07, blue: 0.10)
    static let deepViolet = Color(red: 0.18, green: 0.10, blue: 0.28)
    static let emberGold = Color(red: 1.00, green: 0.62, blue: 0.18)
    static let paperCream = Color(red: 0.96, green: 0.91, blue: 0.82)
}
