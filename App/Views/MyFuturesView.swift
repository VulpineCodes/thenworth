import SwiftData
import SwiftUI
import ThenworthCore

// MARK: - My Futures
//
// The list of saved scenarios from SwiftData: title, kind, created date,
// headline result. Swipe to delete, tap to reopen in Scenario Detail,
// and a compare mode that puts two saved scenarios of the same kind side
// by side.

struct MyFuturesView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \SavedScenarioEntity.updatedAt, order: .reverse)
    private var entities: [SavedScenarioEntity]

    @State private var compareMode = false
    @State private var selectedForCompare: Set<UUID> = []
    @State private var showCompare = false

    private var scenarios: [SavedScenario] {
        entities.compactMap(\.scenario)
    }

    private var selectedScenarios: [SavedScenario] {
        scenarios.filter { selectedForCompare.contains($0.id) }
    }

    private var canCompare: Bool {
        selectedScenarios.count == 2
            && selectedScenarios[0].kind == selectedScenarios[1].kind
    }

    var body: some View {
        NavigationStack {
            Group {
                if scenarios.isEmpty {
                    emptyState
                } else {
                    List {
                        ForEach(scenarios) { scenario in
                            row(scenario)
                        }
                        .onDelete(perform: delete)
                    }
                    .listStyle(.insetGrouped)
                    .scrollContentBackground(.hidden)
                }
            }
            .background(Color.ivoryBackground)
            .navigationTitle("My Futures")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button(compareMode ? "Done" : "Compare") {
                        compareMode.toggle()
                        if !compareMode { selectedForCompare.removeAll() }
                    }
                    .accessibilityIdentifier("compare-toggle-button")
                }
                if compareMode && canCompare {
                    ToolbarItem(placement: .bottomBar) {
                        Button("Compare these two") { showCompare = true }
                            .accessibilityIdentifier("compare-show-button")
                    }
                }
            }
            .sheet(isPresented: $showCompare) {
                if selectedScenarios.count == 2 {
                    CompareView(first: selectedScenarios[0], second: selectedScenarios[1])
                }
            }
            .overlay(alignment: .bottom) {
                if compareMode && selectedScenarios.count == 2 && !canCompare {
                    Text("Pick two scenarios of the same kind to compare.")
                        .font(.thenworthFootnote)
                        .padding(10)
                        .background(Color.cardSurface, in: Capsule())
                        .padding(.bottom, ThenworthSpace.medium)
                }
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: ThenworthSpace.small) {
            Image(systemName: "tray")
                .font(.largeTitle)
                .foregroundStyle(Color.forestPrimary)
            Text("No saved futures yet")
                .font(.thenworthHeadline)
                .foregroundStyle(Color.forestDeep)
            Text("Save a scenario from Home and it will live here, so you can come back to it later.")
                .font(.thenworthBody)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(ThenworthSpace.large)
    }

    @ViewBuilder
    private func row(_ scenario: SavedScenario) -> some View {
        if compareMode {
            Button {
                toggleSelection(scenario)
            } label: {
                rowContent(scenario)
            }
            .buttonStyle(.plain)
            .listRowBackground(Color.cardSurface)
        } else {
            NavigationLink(destination: ScenarioDetailView(scenario: scenario)) {
                rowContent(scenario)
            }
            .accessibilityIdentifier("saved-scenario-\(scenario.id.uuidString)")
            .listRowBackground(Color.cardSurface)
        }
    }

    private func rowContent(_ scenario: SavedScenario) -> some View {
        HStack(alignment: .top, spacing: ThenworthSpace.medium) {
            if compareMode {
                Image(systemName: selectedForCompare.contains(scenario.id)
                    ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(Color.forestPrimary)
                    .padding(.top, 2)
            } else {
                Image(systemName: scenario.kind.systemImage)
                    .foregroundStyle(Color.forestPrimary)
                    .padding(.top, 2)
            }
            VStack(alignment: .leading, spacing: 4) {
                Text(scenario.title)
                    .font(.thenworthHeadline)
                    .foregroundStyle(Color.forestDeep)
                Text("\(scenario.kind.displayTitle) · \(scenario.createdAt.formatted(date: .abbreviated, time: .omitted))")
                    .font(.thenworthFootnote)
                    .foregroundStyle(.secondary)
                Text(scenario.headlineText)
                    .font(.thenworthCaption)
                    .foregroundStyle(Color.primary)
            }
        }
        .padding(.vertical, 4)
    }

    private func toggleSelection(_ scenario: SavedScenario) {
        if selectedForCompare.contains(scenario.id) {
            selectedForCompare.remove(scenario.id)
        } else if selectedForCompare.count < 2 {
            selectedForCompare.insert(scenario.id)
        }
    }

    private func delete(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(entities[index])
        }
        try? modelContext.save()
    }
}

// MARK: - Compare sheet

/// Two saved scenarios of the same kind, final values side by side.
private struct CompareView: View {
    let first: SavedScenario
    let second: SavedScenario

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: ThenworthSpace.large) {
                    Text("Same kind, side by side. Both figures are final values in today's dollars, under each scenario's own assumptions.")
                        .font(.thenworthCaption)
                        .foregroundStyle(.secondary)
                    HStack(alignment: .top, spacing: ThenworthSpace.medium) {
                        compareColumn(first)
                        Divider()
                        compareColumn(second)
                    }
                    StatRow(
                        label: "Difference",
                        value: MoneyFormat.currency(abs(first.finalReal - second.finalReal)),
                        footnote: first.finalReal >= second.finalReal
                            ? "\"\(first.title)\" comes out ahead."
                            : "\"\(second.title)\" comes out ahead."
                    )
                    HypotheticalNote()
                }
                .padding(ThenworthSpace.medium)
            }
            .background(Color.ivoryBackground)
            .navigationTitle("Compare")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    private func compareColumn(_ scenario: SavedScenario) -> some View {
        VStack(alignment: .leading, spacing: ThenworthSpace.small) {
            Text(scenario.title)
                .font(.thenworthHeadline)
                .foregroundStyle(Color.forestDeep)
            Text(scenario.kind.displayTitle)
                .font(.thenworthFootnote)
                .foregroundStyle(.secondary)
            Text(MoneyFormat.currency(scenario.finalReal))
                .font(.thenworthDisplay)
                .foregroundStyle(Color.forestPrimary)
            Text("\(MoneyFormat.currency(scenario.finalNominal)) in future dollars")
                .font(.thenworthFootnote)
                .foregroundStyle(.secondary)
            Text(scenario.headlineText)
                .font(.thenworthCaption)
                .foregroundStyle(Color.primary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
