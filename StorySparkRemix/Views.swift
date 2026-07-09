import SwiftUI

struct TodaySparkView: View {
    @EnvironmentObject private var store: SparkStore
    @Binding var selectedTab: Int

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    DarkPageHeader(title: "Story Spark Remix", subtitle: "A twelve-minute sprint from blank page to micro-fiction draft")
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
            .navigationBarHidden(true)
        }
    }
}

struct RemixLabView: View {
    @EnvironmentObject private var store: SparkStore
    @EnvironmentObject private var premiumStore: PremiumStore
    @AppStorage(SparkPersistenceKeys.sprintMinutes) private var sprintMinutes = 12
    @Binding var selectedTab: Int
    @Binding var draftTitle: String
    @Binding var draftBody: String
    @State private var seedPhrase = ""

    private let starterPhrases = [
        "A key arrives with tomorrow’s date.",
        "The last train carries a paper moon.",
        "A cracked teacup starts answering questions."
    ]

    private var canBuildSpark: Bool {
        !seedPhrase.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    HStack(alignment: .top) {
                        DarkPageHeader(title: "Remix Lab", subtitle: "Capture one rough idea. Shape the constraints before you sprint.")
                        Spacer()
                        Button("Done") { hideKeyboard() }
                            .foregroundColor(.emberGold)
                            .accessibilityLabel("Dismiss keyboard")
                    }
                    CaptureIdeaCard(
                        seedPhrase: $seedPhrase,
                        starterPhrases: starterPhrases,
                        onPickStarter: applyStarter,
                        onBuild: buildSpark,
                        canBuild: canBuildSpark
                    )
                    if let spark = store.editingSpark {
                        SparkCardEditor(spark: spark) { changed in
                            store.updateEditingSpark(changed)
                        }
                        PremiumDeckTeaser(isUnlocked: premiumStore.isPremiumUnlocked) {
                            Task { await premiumStore.loadProducts() }
                        }
                        Button("Start \(sprintMinutes)-Minute Sprint") { startSprint(with: spark) }
                            .buttonStyle(PrimarySparkButtonStyle())
                    } else {
                        EmptyNotebookView(title: "No SparkCard yet", message: "Write one messy sentence or tap a starter. We’ll split it into editable story constraints.")
                    }
                }
                .padding()
            }
            .background(Color.midnightPaper.ignoresSafeArea())
            .navigationBarHidden(true)
        }
    }

    private func applyStarter(_ phrase: String) {
        seedPhrase = phrase
        store.remix(seedPhrase: phrase)
    }

    private func buildSpark() {
        guard canBuildSpark else { return }
        store.remix(seedPhrase: seedPhrase)
        hideKeyboard()
    }

    private func startSprint(with spark: SparkCard) {
        draftTitle = spark.title
        draftBody = "Start with: \(spark.sentenceConstraint)\n\n\(spark.seedPhrase)\n\n"
        selectedTab = 2
    }

    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

struct SparkShelfView: View {
    @EnvironmentObject private var store: SparkStore
    @AppStorage(SparkPersistenceKeys.sprintMinutes) private var sprintMinutes = 12
    @Binding var selectedTab: Int
    @Binding var draftTitle: String
    @Binding var draftBody: String
    @State private var deleteConfirmation = DraftDeleteConfirmation()

    var body: some View {
        NavigationView {
            List {
                SprintWriterSection(draftTitle: $draftTitle, draftBody: $draftBody)
                if store.drafts.isEmpty {
                    EmptyNotebookView(
                        title: "Your shelf is blank",
                        message: "Create the first SparkCard, sprint for \(sprintMinutes) minutes, and save a micro-fiction draft.",
                        actionTitle: "Open Remix Lab"
                    ) { selectedTab = 1 }
                    .listRowBackground(Color.clear)
                } else {
                    ForEach(DraftStatus.allCases) { status in
                        Section(header: Text(status.rawValue)) {
                            ForEach(store.drafts.filter { $0.status == status }) { draft in
                                DraftPulseCard(draft: draft) {
                                    store.beginEditingDraft(draft)
                                    draftTitle = draft.title
                                    draftBody = draft.body
                                } onDelete: {
                                    deleteConfirmation.requestDelete(draft)
                                }
                            }
                        }
                    }
                }
            }
            .listStyle(InsetGroupedListStyle())
            .navigationTitle("Spark Shelf")
            .toolbar { Button("Remix") { selectedTab = 1 } }
            .alert(item: $deleteConfirmation.candidate) { draft in
                Alert(
                    title: Text("Delete \"\(draft.title)\"?"),
                    message: Text("This removes the saved microdraft from this device."),
                    primaryButton: .destructive(Text("Delete")) { deleteConfirmation.confirmDelete(draft, in: store) },
                    secondaryButton: .cancel { deleteConfirmation.cancel() }
                )
            }
        }
    }
}

struct SprintWriterSection: View {
    @EnvironmentObject private var store: SparkStore
    @AppStorage(SparkPersistenceKeys.sprintMinutes) private var sprintMinutes = 12
    @Binding var draftTitle: String
    @Binding var draftBody: String
    @State private var saveMessage: String?

    private var wordCount: Int {
        draftBody.split { $0.isWhitespace || $0.isNewline }.count
    }

    private var canSave: Bool {
        !draftTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !draftBody.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        Section {
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .firstTextBaseline) {
                    Text("\(sprintMinutes)-Minute Sprint")
                        .font(.headline)
                    Spacer()
                    Label("\(sprintMinutes) min target", systemImage: "timer")
                        .font(.caption.weight(.semibold))
                        .foregroundColor(.secondary)
                }
                if let spark = store.editingSpark {
                    SprintSparkCard(spark: spark)
                } else {
                    Text("No SparkCard selected yet. Open Remix Lab first, or save with today's starter.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                TextField("Title this sprint", text: $draftTitle)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .accessibilityLabel("Microdraft title")
                    .accessibilityIdentifier("microdraft-title-field")
                ZStack(alignment: .topLeading) {
                    TextEditor(text: $draftBody)
                        .frame(minHeight: 220)
                        .padding(4)
                        .accessibilityLabel("Microdraft body")
                        .accessibilityIdentifier("microdraft-body-editor")
                    if draftBody.isEmpty {
                        Text("Start with the moment the object changes hands…")
                            .foregroundColor(.secondary.opacity(0.75))
                            .padding(.top, 12)
                            .padding(.leading, 10)
                            .allowsHitTesting(false)
                    }
                }
                .background(Color.white)
                .cornerRadius(14)
                .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.emberGold.opacity(0.35)))
                if let saveMessage = saveMessage {
                    Label(saveMessage, systemImage: "checkmark.circle.fill")
                        .font(.footnote.weight(.semibold))
                        .foregroundColor(.green)
                        .accessibilityLabel(saveMessage)
                }
                HStack {
                    Text("\(wordCount) words")
                    Spacer()
                    Button(saveMessage == nil ? "Save Draft" : "Saved") { saveDraft() }
                        .buttonStyle(PrimarySparkButtonStyle())
                        .disabled(!canSave)
                        .opacity(canSave ? 1 : 0.55)
                        .accessibilityHint(canSave ? "Save this microdraft to the shelf" : "Add a title and one line before saving")
                        .accessibilityIdentifier("save-microdraft-button")
                }
                .font(.caption)
                if let error = store.errorMessage {
                    Text(error)
                        .font(.footnote.weight(.semibold))
                        .foregroundColor(.red)
                        .accessibilityLabel("Save error: \(error)")
                }
            }
            .padding(.vertical, 8)
        }
    }

    private func saveDraft() {
        if store.saveDraft(title: draftTitle, body: draftBody) {
            saveMessage = "Saved to Shelf. Revision beat is ready."
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
    @AppStorage(SparkPersistenceKeys.sprintMinutes) private var sprintMinutes = 12
    @AppStorage(SparkPersistenceKeys.localOnlyMode) private var localOnlyMode = true

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Privacy")) {
                    Text("Your ideas, SparkCards, drafts, preferences, and revision beats stay on this device unless you choose to export them in a future version.")
                    Toggle("Local-only writing mode", isOn: $localOnlyMode)
                    Text("Starter spark decks are bundled local examples and are editable before use.")
                    Text("Locale: English (United States).")
                }
                Section(header: Text("Writing Preferences")) {
                    Picker("Sprint length", selection: $sprintMinutes) {
                        Text("8 minutes").tag(8)
                        Text("12 minutes").tag(12)
                        Text("20 minutes").tag(20)
                    }
                }
                Section(header: Text("Premium")) {
                    Text("Premium will unlock expanded decks, unlimited saved sparks, and advanced style packs. The core writing sprint stays free.")
                    Text(premiumStore.isPremiumUnlocked ? "Premium is unlocked on this device." : "Premium is locked. Purchases and restores use StoreKit 2 only.")
                        .foregroundColor(.secondary)
                    if let message = premiumStore.unavailableMessage { Text(message).foregroundColor(.secondary) }
                    Button("Check Premium") { Task { await premiumStore.loadProducts() } }
                    Button("Unlock Premium") { Task { await premiumStore.purchasePremium() } }
                    Button("Restore Purchases") { Task { await premiumStore.restorePurchases() } }
                }
            }
            .navigationTitle("Settings")
        }
    }
}

private struct DarkPageHeader: View {
    let title: String
    let subtitle: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.largeTitle.bold())
                .foregroundColor(.paperCream)
                .accessibilityAddTraits(.isHeader)
            Text(subtitle)
                .font(.subheadline)
                .foregroundColor(.paperCream.opacity(0.72))
        }
        .accessibilityElement(children: .combine)
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

private struct CaptureIdeaCard: View {
    @Binding var seedPhrase: String
    let starterPhrases: [String]
    let onPickStarter: (String) -> Void
    let onBuild: () -> Void
    let canBuild: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("1. Catch the raw spark")
                .font(.headline)
            Text("Messy is fine. One concrete image is enough.")
                .font(.subheadline)
                .foregroundColor(.secondary)
            ZStack(alignment: .topLeading) {
                TextEditor(text: $seedPhrase)
                    .frame(minHeight: 96)
                    .padding(4)
                    .accessibilityLabel("Raw story idea")
                if seedPhrase.isEmpty {
                    Text("Example: A commuter finds a ticket stamped tomorrow.")
                        .foregroundColor(.secondary.opacity(0.75))
                        .padding(.top, 12)
                        .padding(.leading, 10)
                        .allowsHitTesting(false)
                }
            }
            .background(Color.white)
            .cornerRadius(14)
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.emberGold.opacity(0.3)))
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(starterPhrases, id: \.self) { phrase in
                        Button(phrase) { onPickStarter(phrase) }
                            .font(.caption.weight(.semibold))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(Color.emberGold.opacity(0.18))
                            .foregroundColor(.black)
                            .cornerRadius(999)
                            .accessibilityLabel("Starter idea, \(phrase)")
                    }
                }
            }
            Button("Turn Into SparkCard") { onBuild() }
                .buttonStyle(PrimarySparkButtonStyle())
                .disabled(!canBuild)
                .opacity(canBuild ? 1 : 0.55)
        }
        .padding()
        .background(Color.paperCream)
        .cornerRadius(24)
    }
}

private struct PremiumDeckTeaser: View {
    let isUnlocked: Bool
    let onCheckPremium: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(isUnlocked ? "Premium deck unlocked" : "Premium deck preview", systemImage: "crown")
                .font(.headline)
            Text(isUnlocked ? "Expanded genre decks are available for this sprint." : "Locked genre decks stay visible as a teaser. Unlock through StoreKit 2 or keep using the free local deck.")
                .font(.subheadline)
                .foregroundColor(.secondary)
            if !isUnlocked {
                Button("Check Premium Access", action: onCheckPremium)
                    .buttonStyle(PrimarySparkButtonStyle())
            }
        }
        .padding()
        .background(Color.paperCream)
        .cornerRadius(24)
    }
}

private struct SparkCardEditor: View {
    var spark: SparkCard
    var onChange: (SparkCard) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("2. Tune the constraints")
                .font(.headline)
            Text("Each field stays editable before the sprint starts.")
                .font(.subheadline)
                .foregroundColor(.secondary)
            IngredientInputRow(label: "Genre", icon: "die.face.5", text: binding(\.genre))
            IngredientInputRow(label: "Pressure", icon: "person.crop.circle.badge.exclamationmark", text: binding(\.characterPressure))
            IngredientInputRow(label: "Odd Object", icon: "shippingbox", text: binding(\.oddObject))
            IngredientInputRow(label: "Twist", icon: "arrow.triangle.2.circlepath", text: binding(\.twist))
            IngredientInputRow(label: "Sentence Constraint", icon: "text.quote", text: binding(\.sentenceConstraint))
        }
        .padding()
        .background(Color.paperCream)
        .cornerRadius(24)
    }

    private func binding(_ keyPath: WritableKeyPath<SparkCard, String>) -> Binding<String> {
        Binding(
            get: { spark[keyPath: keyPath] },
            set: { newValue in
                var changed = spark
                changed[keyPath: keyPath] = newValue
                onChange(changed)
            }
        )
    }
}

private struct IngredientInputRow: View {
    let label: String
    let icon: String
    @Binding var text: String

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: icon)
                .frame(width: 24)
                .foregroundColor(.emberGold)
            VStack(alignment: .leading, spacing: 4) {
                Text(label)
                    .font(.caption.bold())
                    .foregroundColor(.secondary)
                TextField(label, text: $text)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .accessibilityLabel("\(label) field")
            }
        }
    }
}

private struct SprintSparkCard: View {
    let spark: SparkCard

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(spark.title)
                .font(.subheadline.weight(.semibold))
            Text("Opening move: \(spark.sentenceConstraint)")
                .font(.caption)
                .foregroundColor(.secondary)
            Text("Pressure: \(spark.characterPressure)")
                .font(.caption)
                .foregroundColor(.secondary)
            SparkSummary(spark: spark)
                .padding(10)
                .background(Color.midnightPaper)
                .cornerRadius(14)
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
                    .buttonStyle(.borderless)
                    .accessibilityIdentifier("edit-draft-button")
                Spacer()
                Button("Delete") { onDelete() }
                    .buttonStyle(.borderless)
                    .foregroundColor(.red)
                    .accessibilityIdentifier("delete-draft-button")
            }
        }
        .padding(14)
        .background(Color.paperCream)
        .cornerRadius(18)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Draft pulse card, \(draft.title), \(draft.status.rawValue)")
    }
}

private struct EmptyNotebookView: View {
    let title: String
    let message: String
    var actionTitle: String? = nil
    var action: (() -> Void)? = nil

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "book.closed")
                .font(.system(size: 44))
                .foregroundColor(.emberGold)
            Text(title).font(.headline)
            Text(message).font(.subheadline).multilineTextAlignment(.center).foregroundColor(.secondary)
            if let actionTitle, let action {
                Button(actionTitle, action: action)
                    .buttonStyle(PrimarySparkButtonStyle())
            }
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
