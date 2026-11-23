import Charts
import SwiftUI
import ThenworthCore

// MARK: - Future Lens
//
// THE signature interaction. A fork visualization: two paths diverge from
// the decision point and the gap between them is shaded. The gap IS the
// tradeoff.
//
// The chart is driven by `ScenarioViewModel` (Combine): the scrubbed
// year, the dollars basis, and the scenario inputs flow into one derived
// `LensComputation`, so the chart, the figures, and the milestone line
// can never disagree.
//
// Requirements honored here:
// - Big thumb-friendly timeline scrubber (slider plus year steppers).
// - Animated counting numbers while scrubbing, gated by reduced motion.
// - Today's-dollars / future-dollars toggle, defaulting to today's.
// - A concrete-milestone line from `Milestones.translation(for:)`.
// - Neutral, non-judgmental path labels, plus one line acknowledging
//   what spending gives you today. Never shames spending.

struct FutureLensView: View {
    @ObservedObject var viewModel: ScenarioViewModel
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        let lens = viewModel.lens
        VStack(alignment: .leading, spacing: ThenworthSpace.medium) {
            HStack {
                Text("The fork")
                    .font(.thenworthTitle)
                    .foregroundStyle(Color.forestDeep)
                Spacer()
                DollarsToggle(basis: $viewModel.basis)
                    .frame(width: 180)
            }

            Text("Two paths from one decision. The shaded gap between them is what the choice is worth.")
                .font(.thenworthCaption)
                .foregroundStyle(.secondary)

            chart(lens: lens)
            figures(lens: lens)
            MilestoneLine(text: lens.milestone.map { "That gap is \($0)." })
            Text(lens.acknowledgment)
                .font(.thenworthCaption)
                .foregroundStyle(.secondary)
            scrubber(lens: lens)
            HypotheticalNote()
        }
        .padding(ThenworthSpace.medium)
        .background(Color.cardSurface, in: RoundedRectangle(cornerRadius: ThenworthRadius.card))
        .overlay(
            RoundedRectangle(cornerRadius: ThenworthRadius.card)
                .stroke(Color.softBorder, lineWidth: 1)
        )
    }

    // MARK: Chart

    @ViewBuilder
    private func chart(lens: LensComputation) -> some View {
        Chart {
            ForEach(lens.points) { point in
                AreaMark(
                    x: .value("Year", point.year),
                    yStart: .value("Lower", point.lower),
                    yEnd: .value("Upper", point.upper)
                )
                .interpolationMethod(.catmullRom)
                .foregroundStyle(Color.growthAccent.opacity(0.22))
            }
            ForEach(lens.points) { point in
                LineMark(
                    x: .value("Year", point.year),
                    y: .value("Amount", point.first)
                )
                .interpolationMethod(.catmullRom)
                .foregroundStyle(Color.secondary)
                .lineStyle(StrokeStyle(lineWidth: 2))
            }
            ForEach(lens.points) { point in
                LineMark(
                    x: .value("Year", point.year),
                    y: .value("Amount", point.second)
                )
                .interpolationMethod(.catmullRom)
                .foregroundStyle(Color.growthAccent)
                .lineStyle(StrokeStyle(lineWidth: 2.5))
            }
            RuleMark(x: .value("Selected year", lens.selectedYear))
                .foregroundStyle(Color.forestPrimary)
                .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 4]))
        }
        .chartXScale(domain: 0...max(lens.maxYears, 1))
        .chartXAxis {
            AxisMarks(values: .stride(by: max(1, lens.maxYears / 4))) { value in
                AxisGridLine()
                AxisValueLabel {
                    if let year = value.as(Int.self) {
                        Text("Yr \(year)")
                    }
                }
            }
        }
        .chartYAxis {
            AxisMarks { value in
                AxisGridLine()
                AxisValueLabel(format: .currency(code: "USD").precision(.fractionLength(0)))
            }
        }
        .frame(height: 240)
        .accessibilityLabel(chartSummary(lens: lens))
        .accessibilityHidden(false)
    }

    private func chartSummary(lens: LensComputation) -> String {
        "Chart of two paths over \(lens.maxYears) years. " +
        "\(lens.firstLabel): \(MoneyFormat.currency(lens.selectedFirst)) at year \(lens.selectedYear). " +
        "\(lens.secondLabel): \(MoneyFormat.currency(lens.selectedSecond)). " +
        "Gap: \(MoneyFormat.currency(lens.selectedGap))."
    }

    // MARK: Figures at the scrubbed year

    @ViewBuilder
    private func figures(lens: LensComputation) -> some View {
        VStack(alignment: .leading, spacing: ThenworthSpace.small) {
            HStack {
                PathLabelChip(text: lens.firstLabel, tone: .spend)
                Spacer()
                countingText(MoneyFormat.currency(lens.selectedFirst))
            }
            HStack {
                PathLabelChip(text: lens.secondLabel, tone: .grow)
                Spacer()
                countingText(MoneyFormat.currency(lens.selectedSecond))
            }
            Divider()
            HStack {
                Text("The gap")
                    .font(.thenworthHeadline)
                    .foregroundStyle(Color.forestDeep)
                Spacer()
                countingText(MoneyFormat.currency(lens.selectedGap))
                    .font(.thenworthDisplay)
            }
            Text("Year \(lens.selectedYear) of \(lens.maxYears) · \(viewModel.basis.label)")
                .font(.thenworthFootnote)
                .foregroundStyle(.secondary)
                .accessibilityIdentifier("lens-year-label")
        }
    }

    /// A number that animates as it counts while scrubbing, unless the
    /// user has reduced motion on.
    private func countingText(_ text: String) -> some View {
        Text(text)
            .font(.thenworthHeadline)
            .foregroundStyle(Color.forestDeep)
            .contentTransition(.numericText())
            .animation(
                reduceMotion ? nil : .easeInOut(duration: 0.25),
                value: viewModel.scrubbedYear
            )
    }

    // MARK: Timeline scrubber

    @ViewBuilder
    private func scrubber(lens: LensComputation) -> some View {
        VStack(alignment: .leading, spacing: ThenworthSpace.small) {
            Text("Drag the timeline")
                .font(.thenworthFootnote)
                .fontWeight(.semibold)
                .foregroundStyle(Color.forestPrimary)
            HStack(spacing: ThenworthSpace.medium) {
                Button {
                    viewModel.scrubbedYear = max(0, viewModel.scrubbedYear - 1)
                } label: {
                    Image(systemName: "minus.circle.fill")
                        .font(.title2)
                        .foregroundStyle(Color.forestPrimary)
                }
                .frame(minWidth: 44, minHeight: 44)
                .accessibilityIdentifier("year-stepper-minus")
                .accessibilityLabel("One year earlier")

                Slider(
                    value: $viewModel.scrubbedYear,
                    in: 0...Double(max(lens.maxYears, 1)),
                    step: 1
                )
                .frame(minHeight: 44)
                .accessibilityIdentifier("timeline-scrubber")
                .accessibilityLabel("Timeline year")
                .accessibilityValue("\(lens.selectedYear) years")

                Button {
                    viewModel.scrubbedYear = min(Double(lens.maxYears), viewModel.scrubbedYear + 1)
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                        .foregroundStyle(Color.forestPrimary)
                }
                .frame(minWidth: 44, minHeight: 44)
                .accessibilityIdentifier("year-stepper-plus")
                .accessibilityLabel("One year later")
            }
        }
    }
}
