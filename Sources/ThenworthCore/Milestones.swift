import Foundation

/// Translates a dollar amount into a short, concrete, non-judgmental
/// comparison, so an abstract future value feels tangible.
/// Pure and deterministic. US-anchored, rough everyday costs.
public enum Milestones {

    /// A concrete comparison for the amount, or nil for very small amounts
    /// (under $15) where no comparison is meaningful.
    public static func translation(for amount: Double) -> String? {
        let amount = max(0, amount)
        switch amount {
        case ..<15:
            return nil
        case ..<75:
            return "about a dinner out"
        case ..<350:
            return "about a month of groceries"
        case ..<1_500:
            return "about a month of rent"
        case ..<4_500:
            return "about 3 months of rent"
        case ..<12_000:
            return "about a used car"
        case ..<20_000:
            return "about a year of rent"
        case ..<45_000:
            return "about a year of college tuition"
        case ..<80_000:
            return "about a home down payment"
        default:
            return "about a year of salary"
        }
    }
}
