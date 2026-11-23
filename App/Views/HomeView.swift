import SwiftUI
import ThenworthCore

// MARK: - Home
//
// The question first, then four scenario cards built from the sample
// scenarios, each showing a live mini-preview computed from the core.
// Tapping a card opens its Scenario Detail.

struct HomeView: View {
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: ThenworthSpace.large) {
                    header
                    examplesSection
                    scratchSection
                    footerNote
                }
                .padding(ThenworthSpace.medium)
            }
            .background(Color.ivoryBackground)
            .navigationTitle("Thenworth")
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: ThenworthSpace.small) {
            Text("What does today mean for tomorrow?")
                .font(.thenworthDisplay)
                .foregroundStyle(Color.forestDeep)
            Text("Pick a decision and see both paths: what it gives you now, and what it could become. No judgment either way.")
                .font(.thenworthBody)
                .foregroundStyle(.secondary)
        }
        .padding(.top, ThenworthSpace.small)
    }

    private var examplesSection: some View {
        VStack(alignment: .leading, spacing: ThenworthSpace.small) {
            Text("Start with an example")
                .font(.thenworthHeadline)
                .foregroundStyle(Color.forestDeep)
            ForEach(SampleScenarios.all) { sample in
                NavigationLink(destination: ScenarioDetailView(scenario: sample)) {
                    scenarioCard(sample)
                }
                .accessibilityIdentifier("scenario-card-\(sample.kind.rawValue)")
                .buttonStyle(.plain)
            }
        }
    }

    private func scenarioCard(_ scenario: SavedScenario) -> some View {
        HStack(alignment: .top, spacing: ThenworthSpace.medium) {
            Image(systemName: scenario.kind.systemImage)
                .font(.title2)
                .foregroundStyle(Color.forestPrimary)
                .frame(width: 44, height: 44)
                .background(Color.growthAccent.opacity(0.14), in: RoundedRectangle(cornerRadius: ThenworthRadius.small))
            VStack(alignment: .leading, spacing: 4) {
                Text(scenario.title)
                    .font(.thenworthHeadline)
                    .foregroundStyle(Color.forestDeep)
                Text(scenario.kind.subtitle)
                    .font(.thenworthFootnote)
                    .foregroundStyle(.secondary)
                Text(scenario.headlineText)
                    .font(.thenworthCaption)
                    .foregroundStyle(Color.primary)
                    .padding(.top, 2)
            }
            Spacer()
            Image(systemName: "chevron.right")
                .foregroundStyle(.secondary)
                .padding(.top, 6)
        }
        .padding(ThenworthSpace.medium)
        .background(Color.cardSurface, in: RoundedRectangle(cornerRadius: ThenworthRadius.card))
        .overlay(
            RoundedRectangle(cornerRadius: ThenworthRadius.card)
                .stroke(Color.softBorder, lineWidth: 1)
        )
    }

    private var scratchSection: some View {
        VStack(alignment: .leading, spacing: ThenworthSpace.small) {
            Text("Start from scratch")
                .font(.thenworthHeadline)
                .foregroundStyle(Color.forestDeep)
            LazyVGrid(
                columns: [GridItem(.flexible()), GridItem(.flexible())],
                spacing: ThenworthSpace.small
            ) {
                ForEach([ScenarioKind.oneTime, .recurring, .goal, .retirement], id: \.self) { kind in
                    NavigationLink(destination: ScenarioDetailView(scenario: .blank(kind: kind), isNew: true)) {
                        VStack(alignment: .leading, spacing: 6) {
                            Image(systemName: kind.systemImage)
                                .font(.title3)
                                .foregroundStyle(Color.forestPrimary)
                            Text(kind.displayTitle)
                                .font(.thenworthHeadline)
                                .foregroundStyle(Color.forestDeep)
                            Text(kind.subtitle)
                                .font(.thenworthFootnote)
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(ThenworthSpace.medium)
                        .background(Color.cardSurface, in: RoundedRectangle(cornerRadius: ThenworthRadius.card))
                        .overlay(
                            RoundedRectangle(cornerRadius: ThenworthRadius.card)
                                .stroke(Color.softBorder, lineWidth: 1)
                        )
                    }
                    .accessibilityIdentifier("new-scenario-\(kind.rawValue)")
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var footerNote: some View {
        VStack(alignment: .leading, spacing: ThenworthSpace.small) {
            HypotheticalNote()
            Text("Thenworth works offline. Nothing you enter leaves this device, and there is no account.")
                .font(.thenworthFootnote)
                .foregroundStyle(.secondary)
        }
    }
}
