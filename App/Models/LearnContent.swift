import Foundation

// MARK: - Learn Why content
//
// Short, plain-language explainers for the four ideas Thenworth is built
// on. Plain data only: no networking, no tracking, no claims about any
// medical condition. Thenworth does not diagnose ADHD or any other
// condition, and nothing here suggests otherwise.

/// One Learn Why topic.
struct LearnTopic: Identifiable {
    let id: String
    /// SF Symbol name.
    let icon: String
    let title: String
    /// One paragraph, plain language.
    let explanation: String
    /// One line on why it matters for a decision today.
    let whyItMatters: String

    /// A short line tying the idea back to the app, shown at the end of
    /// the detail screen.
    let tryIt: String
}

enum LearnContent {
    static let all: [LearnTopic] = [
        LearnTopic(
            id: "compounding",
            icon: "chart.line.uptrend.xyaxis",
            title: "Compounding",
            explanation: "When money you set aside earns a return, that return can earn a return of its own. Early on the growth looks small, because there is not much there yet. Given enough years, the growth on the growth becomes the biggest part of the total. That is why the same monthly amount can end up very different depending on when you start.",
            whyItMatters: "Starting earlier usually matters more than starting bigger.",
            tryIt: "Compare starting retirement saving at 23 versus 30 in the Future Lens and watch the gap open up over time."
        ),
        LearnTopic(
            id: "opportunity-cost",
            icon: "arrow.left.arrow.right",
            title: "Opportunity cost",
            explanation: "Every dollar has more than one possible job. Spending it today buys something now. Setting it aside buys whatever that money could become later. Neither choice is wrong on its own. Opportunity cost is simply the name for what you give up when you pick one job for the dollar instead of the other.",
            whyItMatters: "Seeing both sides of a choice makes the tradeoff real instead of abstract.",
            tryIt: "Open any one-time scenario and look at both paths in the Future Lens: what you get today, and what it could become."
        ),
        LearnTopic(
            id: "inflation",
            icon: "banknote",
            title: "Inflation",
            explanation: "Prices tend to rise over time, so a dollar in twenty years usually buys less than a dollar today. That is why Thenworth shows two views of every future amount: future dollars, the number on the price tag in that year, and today's dollars, what that amount would buy if prices stayed where they are now. The today's-dollars view is the default, because it is the easier one to feel.",
            whyItMatters: "A big future number can be misleading until you adjust for what things will cost.",
            tryIt: "Flip the dollars toggle in the Future Lens between today's dollars and future dollars and see how the same plan changes."
        ),
        LearnTopic(
            id: "temporal-discounting",
            icon: "hourglass",
            title: "Why the future feels far away",
            explanation: "People tend to value something now more than the same thing later, even when waiting would pay off. Psychologists call this temporal discounting. It is a normal part of how brains weigh time, not a personal failure. Making the future concrete, picturing what a sum could actually buy, can shrink that distance a little.",
            whyItMatters: "A vague future is easy to ignore. A concrete one is easier to care about.",
            tryIt: "Scrub the timeline in the Future Lens and read the milestone line: the app translates a future sum into something concrete, like a used car."
        ),
    ]
}
