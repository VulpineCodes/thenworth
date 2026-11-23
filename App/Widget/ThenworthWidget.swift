import SwiftData
import SwiftUI
import ThenworthCore
import WidgetKit

// MARK: - Thenworth widget (WidgetKit)
//
// A home-screen widget showing one saved scenario's future value, in
// today's dollars. Static configuration: no user settings, just the most
// recently updated saved scenario.
//
// Extension-target code. It does NOT compile on the Linux VM and it is
// NOT part of the app target: it lives in its own Widget Extension
// target in Xcode (see App/README.md for the setup, including the App
// Group the widget shares with the app).
//
// The widget reads the same SwiftData store as the app through the App
// Group. `SavedScenarioEntity` and the design system come from the app
// target's files, added to the widget target's membership (see README).

struct ThenworthEntry: TimelineEntry {
    let date: Date
    /// The most recently updated saved scenario, or nil when nothing is
    /// saved yet (the widget then shows a sample).
    let scenario: SavedScenario?
}

struct ThenworthProvider: TimelineProvider {
    func placeholder(in context: Context) -> ThenworthEntry {
        ThenworthEntry(date: Date(), scenario: SampleScenarios.all.first)
    }

    func getSnapshot(in context: Context, completion: @escaping (ThenworthEntry) -> Void) {
        completion(ThenworthEntry(date: Date(), scenario: latestScenario() ?? SampleScenarios.all.first))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<ThenworthEntry>) -> Void) {
        let entry = ThenworthEntry(date: Date(), scenario: latestScenario())
        // Values only change when the user edits a scenario in the app,
        // so an hourly refresh is plenty.
        let nextUpdate = Calendar.current.date(byAdding: .hour, value: 1, to: Date()) ?? Date()
        completion(Timeline(entries: [entry], policy: .after(nextUpdate)))
    }

    /// Read the most recently updated scenario from the shared store.
    /// Returns nil when the store is empty or unreadable; the widget
    /// shows its empty state instead of failing.
    private func latestScenario() -> SavedScenario? {
        do {
            let configuration = ModelConfiguration(
                schema: Schema([SavedScenarioEntity.self]),
                groupContainer: .identifier(ThenworthAppGroup.identifier)
            )
            let container = try ModelContainer(
                for: SavedScenarioEntity.self,
                configurations: [configuration]
            )
            let descriptor = FetchDescriptor<SavedScenarioEntity>(
                sortBy: [SortDescriptor(\.updatedAt, order: .reverse)]
            )
            return try container.mainContext.fetch(descriptor).first?.scenario
        } catch {
            return nil
        }
    }
}

struct ThenworthWidgetEntryView: View {
    var entry: ThenworthEntry
    @Environment(\.widgetFamily) private var family

    var body: some View {
        if let scenario = entry.scenario {
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 6) {
                    Image(systemName: scenario.kind.systemImage)
                        .foregroundStyle(Color.forestPrimary)
                    Text(scenario.kind.displayTitle)
                        .font(.footnote)
                        .fontWeight(.semibold)
                        .foregroundStyle(Color.forestPrimary)
                }
                Text(MoneyFormat.currency(scenario.finalReal))
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundStyle(Color.forestDeep)
                Text("in today's dollars")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                if family == .systemMedium {
                    Text(scenario.headlineText)
                        .font(.caption)
                        .foregroundStyle(Color.primary)
                        .lineLimit(2)
                }
                Spacer(minLength: 0)
                Text("Hypothetical, not guaranteed")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
            .padding()
            .background(Color.ivoryBackground)
            .containerBackground(Color.ivoryBackground, for: .widget)
        } else {
            VStack(alignment: .leading, spacing: 6) {
                Text("Thenworth")
                    .font(.headline)
                    .foregroundStyle(Color.forestDeep)
                Text("Save a future in the app and it will show up here.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
            .padding()
            .background(Color.ivoryBackground)
            .containerBackground(Color.ivoryBackground, for: .widget)
        }
    }
}

struct ThenworthWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "ThenworthWidget", provider: ThenworthProvider()) { entry in
            ThenworthWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Thenworth")
        .description("Your next future, at a glance.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

@main
struct ThenworthWidgetBundle: WidgetBundle {
    var body: some Widget {
        ThenworthWidget()
    }
}
