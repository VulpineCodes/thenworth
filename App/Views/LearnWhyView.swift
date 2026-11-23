import SwiftUI

// MARK: - Learn Why
//
// The list and detail for the four ideas Thenworth is built on, driven
// by `LearnContent`. Plain educational copy; no medical claims, no
// diagnosis of any condition.

struct LearnWhyView: View {
    var body: some View {
        NavigationStack {
            List(LearnContent.all) { topic in
                NavigationLink(destination: LearnTopicDetailView(topic: topic)) {
                    HStack(alignment: .top, spacing: ThenworthSpace.medium) {
                        Image(systemName: topic.icon)
                            .font(.title2)
                            .foregroundStyle(Color.forestPrimary)
                            .frame(width: 44, height: 44)
                            .background(Color.growthAccent.opacity(0.14), in: RoundedRectangle(cornerRadius: ThenworthRadius.small))
                        VStack(alignment: .leading, spacing: 4) {
                            Text(topic.title)
                                .font(.thenworthHeadline)
                                .foregroundStyle(Color.forestDeep)
                            Text(topic.whyItMatters)
                                .font(.thenworthCaption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 4)
                }
                .listRowBackground(Color.cardSurface)
                .accessibilityIdentifier("learn-topic-\(topic.id)")
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
            .background(Color.ivoryBackground)
            .navigationTitle("Learn Why")
            .safeAreaInset(edge: .bottom) {
                Text("Educational only. Thenworth is not financial advice, and it does not diagnose or treat any condition.")
                    .font(.thenworthFootnote)
                    .foregroundStyle(.secondary)
                    .padding(ThenworthSpace.medium)
            }
        }
    }
}

private struct LearnTopicDetailView: View {
    let topic: LearnTopic

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: ThenworthSpace.medium) {
                Image(systemName: topic.icon)
                    .font(.largeTitle)
                    .foregroundStyle(Color.forestPrimary)
                Text(topic.title)
                    .font(.thenworthDisplay)
                    .foregroundStyle(Color.forestDeep)
                Text(topic.explanation)
                    .font(.thenworthBody)
                Divider()
                VStack(alignment: .leading, spacing: 4) {
                    Text("Why it matters")
                        .font(.thenworthHeadline)
                        .foregroundStyle(Color.forestDeep)
                    Text(topic.whyItMatters)
                        .font(.thenworthBody)
                }
                VStack(alignment: .leading, spacing: 4) {
                    Text("Try it in Thenworth")
                        .font(.thenworthHeadline)
                        .foregroundStyle(Color.forestDeep)
                    Text(topic.tryIt)
                        .font(.thenworthBody)
                }
                HypotheticalNote()
            }
            .padding(ThenworthSpace.medium)
        }
        .background(Color.ivoryBackground)
        .navigationTitle(topic.title)
        .navigationBarTitleDisplayMode(.inline)
    }
}
