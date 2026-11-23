import SwiftData
import SwiftUI

/// The app entry point.
///
/// ## Xcode setup (Franklin, on your Mac)
///
/// 1. In Xcode: File > New > Project > iOS App. Name it `Thenworth`,
///    interface SwiftUI, language Swift, storage SwiftData.
///    Deployment target iOS 17.
/// 2. Add the `ThenworthCore` package: File > Add Package Dependencies >
///    Add Local > select the `thenworth` folder (the package root, where
///    `Package.swift` lives). Add `ThenworthCore` to the app target.
/// 3. Copy every `.swift` file under `App/` (except `UITests/`,
///    `Widget/`, and `AppIntents/`, which have their own targets; see
///    App/README.md) into the app target.
/// 4. Build and run on a simulator. No camera, no network, no account:
///    every flow works in the simulator.
///
/// This file is the only `@main` entry point; everything else is a view,
/// a model, or the store. This layer was written on a Linux VM and has
/// NOT been compiled; see App/README.md for what to validate on the Mac.
@main
struct ThenworthApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([SavedScenarioEntity.self])
        // Prefer the shared App Group store so the widget reads the same
        // scenarios. Falls back to a private store when the App Group
        // capability has not been added yet (see App/README.md).
        let groupConfiguration = ModelConfiguration(
            schema: schema,
            groupContainer: .identifier(ThenworthAppGroup.identifier),
            isStoredInMemoryOnly: false
        )
        if let container = try? ModelContainer(for: schema, configurations: [groupConfiguration]) {
            return container
        }
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        do {
            return try ModelContainer(for: schema, configurations: [configuration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(sharedModelContainer)
    }
}

/// The root tab view: Home, My Futures, Learn Why.
struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var store = ScenarioStore()

    var body: some View {
        TabView {
            HomeView()
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }
            MyFuturesView()
                .tabItem {
                    Label("My Futures", systemImage: "clock.arrow.2.circlepath")
                }
            LearnWhyView()
                .tabItem {
                    Label("Learn Why", systemImage: "lightbulb.fill")
                }
        }
        .environmentObject(store)
        .task {
            // The store needs the context from the view hierarchy.
            // Seeding inserts the four sample scenarios on first launch.
            store.attach(modelContext: modelContext)
            store.seedIfNeeded()
        }
    }
}
