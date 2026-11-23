import Foundation
import SwiftData
import ThenworthCore

/// The App Group shared by the app and the widget extension, so the
/// widget can read the same SwiftData store. The identifier must match
/// the App Group capability added to both targets in Xcode (see
/// App/README.md). If the group is not set up yet, the app falls back
/// to its own private store; add the group before first launch so saved
/// scenarios do not start in the private store and then move.
enum ThenworthAppGroup {
    static let identifier = "group.com.franklin.thenworth"
}

// MARK: - SwiftData storage for saved scenarios
//
// The portable core owns the math (`SavedScenario`, `ScenarioInputs`).
// This layer owns persistence: one SwiftData entity that stores the
// scenario's inputs as JSON, plus a small store that wraps the
// ModelContext. Everything is local-only; there is no account and no
// backend.
//
// NOTE: Written on the Linux VM; not compiled here. See App/README.md.
// It assumes `ScenarioInputs` is Codable and `ScenarioKind` is a
// String-backed enum, per the locked core API.

/// SwiftData mirror of `SavedScenario`. The inputs are stored as JSON so
/// the entity never has to track the core's input fields one by one.
@Model
final class SavedScenarioEntity {
    @Attribute(.unique) var id: UUID
    /// `ScenarioKind` raw value ("oneTime", "recurring", "goal", "retirement").
    var kind: String
    var title: String
    /// JSON-encoded `ScenarioInputs`.
    var inputsJSON: Data
    var createdAt: Date
    var updatedAt: Date

    init(_ scenario: SavedScenario) {
        self.id = scenario.id
        self.kind = scenario.kind.rawValue
        self.title = scenario.title
        self.inputsJSON = (try? JSONEncoder().encode(scenario.inputs)) ?? Data()
        self.createdAt = scenario.createdAt
        self.updatedAt = scenario.updatedAt
    }

    /// Decode back to the core type. Returns nil when the stored JSON no
    /// longer decodes (for example after a core model change); callers skip
    /// such rows instead of crashing.
    var scenario: SavedScenario? {
        guard let kind = ScenarioKind(rawValue: kind),
              let inputs = try? JSONDecoder().decode(ScenarioInputs.self, from: inputsJSON)
        else { return nil }
        return SavedScenario(
            id: id,
            kind: kind,
            title: title,
            inputs: inputs,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }

    /// Overwrite this row from an edited scenario (same id).
    func update(from scenario: SavedScenario) {
        self.kind = scenario.kind.rawValue
        self.title = scenario.title
        self.inputsJSON = (try? JSONEncoder().encode(scenario.inputs)) ?? Data()
        self.updatedAt = scenario.updatedAt
    }
}

// MARK: - ScenarioStore

/// Wraps the ModelContext for saved scenarios: fetch, save, update,
/// delete, and first-launch seeding from `SampleScenarios.all`.
///
/// Created without a context (the app entry point owns the container)
/// and attached once the view hierarchy provides one.
@MainActor
final class ScenarioStore: ObservableObject {
    @Published private(set) var scenarios: [SavedScenario] = []

    private var context: ModelContext?

    init() {}

    /// Attach the context from the view hierarchy, then load.
    func attach(modelContext: ModelContext) {
        self.context = modelContext
        fetch()
    }

    /// Reload `scenarios` from SwiftData, newest first.
    func fetch() {
        guard let context else { return }
        do {
            let descriptor = FetchDescriptor<SavedScenarioEntity>(
                sortBy: [SortDescriptor(\.updatedAt, order: .reverse)]
            )
            scenarios = try context.fetch(descriptor).compactMap(\.scenario)
        } catch {
            scenarios = []
        }
    }

    /// Insert the sample scenarios the first time the app runs, so Home
    /// and My Futures are never empty. Does nothing when anything is
    /// already saved.
    func seedIfNeeded() {
        guard let context else { return }
        fetch()
        guard scenarios.isEmpty else { return }
        for sample in SampleScenarios.all {
            context.insert(SavedScenarioEntity(sample))
        }
        try? context.save()
        fetch()
    }

    /// Insert a new scenario, or update the row with the same id.
    func save(_ scenario: SavedScenario) {
        guard let context else { return }
        do {
            let descriptor = FetchDescriptor<SavedScenarioEntity>(
                predicate: #Predicate { $0.id == scenario.id }
            )
            if let existing = try context.fetch(descriptor).first {
                existing.update(from: scenario)
            } else {
                context.insert(SavedScenarioEntity(scenario))
            }
            try context.save()
        } catch {
            // Local-only store; a failed save leaves the in-memory list
            // unchanged and the user can retry. Nothing is sent anywhere.
        }
        fetch()
    }

    /// Delete one scenario by id. No-op when it is not stored.
    func delete(_ scenario: SavedScenario) {
        delete(id: scenario.id)
    }

    func delete(id: UUID) {
        guard let context else { return }
        do {
            let descriptor = FetchDescriptor<SavedScenarioEntity>(
                predicate: #Predicate { $0.id == id }
            )
            for entity in try context.fetch(descriptor) {
                context.delete(entity)
            }
            try context.save()
        } catch {
            // See save(_:): local-only, safe to retry.
        }
        fetch()
    }
}
