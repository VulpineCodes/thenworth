import Foundation

/// Deterministic compound-interest engine. All money is in dollars (Double).
/// Negative money, rate, inflation, and time inputs clamp to 0.
/// All returns are hypothetical; nothing here is a guarantee.
public enum FinancialEngine {

    // MARK: - Future value

    /// Future value of a lump sum: P * (1 + r/n)^(n*t).
    /// A zero rate or zero years returns the principal unchanged.
    public static func futureValue(
        principal: Double,
        annualRate: Double,
        years: Double,
        compounding: CompoundingFrequency
    ) -> Double {
        let principal = max(0, principal)
        let rate = max(0, annualRate)
        let years = max(0, years)
        guard rate > 0, years > 0 else { return principal }
        let n = compounding.periodsPerYear
        return principal * pow(1 + rate / n, n * years)
    }

    /// Future value of equal monthly contributions made at the end of each
    /// month. The monthly rate is the effective monthly rate implied by the
    /// annual rate and compounding frequency: (1 + r/n)^(n/12) - 1.
    /// A zero rate returns the plain sum of contributions.
    public static func futureValueOfAnnuity(
        monthlyPayment: Double,
        annualRate: Double,
        years: Double,
        compounding: CompoundingFrequency
    ) -> Double {
        let payment = max(0, monthlyPayment)
        let rate = max(0, annualRate)
        let years = max(0, years)
        let months = 12 * years
        guard payment > 0, months > 0 else { return 0 }
        guard rate > 0 else { return payment * months }
        let n = compounding.periodsPerYear
        let monthlyRate = pow(1 + rate / n, n / 12) - 1
        guard monthlyRate > 0 else { return payment * months }
        return payment * ((pow(1 + monthlyRate, months) - 1) / monthlyRate)
    }

    /// The value of a nominal (future-dollar) amount in today's dollars:
    /// nominal / (1 + inflation)^years. Zero inflation or zero years
    /// returns the nominal amount unchanged.
    public static func realValue(nominal: Double, annualInflation: Double, years: Double) -> Double {
        let nominal = max(0, nominal)
        let inflation = max(0, annualInflation)
        let years = max(0, years)
        guard inflation > 0, years > 0 else { return nominal }
        return nominal / pow(1 + inflation, years)
    }

    /// Total paid for a recurring monthly cost over a horizon, with no return.
    public static func totalPaid(monthlyAmount: Double, years: Double) -> Double {
        max(0, monthlyAmount) * 12 * max(0, years)
    }

    /// What redirecting a recurring monthly payment into savings could
    /// accumulate: the future value of that monthly amount as an annuity.
    /// Same as futureValueOfAnnuity, named for the redirect use case.
    public static func redirectedValue(
        monthlyAmount: Double,
        annualRate: Double,
        years: Double,
        compounding: CompoundingFrequency
    ) -> Double {
        futureValueOfAnnuity(
            monthlyPayment: monthlyAmount,
            annualRate: annualRate,
            years: years,
            compounding: compounding
        )
    }

    // MARK: - Projection

    /// Projects principal plus monthly contributions over a horizon, sampled
    /// every `stepYears` years (plus a point at year 0 and at the final year).
    /// `nominal` is in future dollars; `real` is in today's dollars.
    public static func project(
        principal: Double,
        monthlyContribution: Double,
        annualRate: Double,
        annualInflation: Double,
        years: Double,
        compounding: CompoundingFrequency,
        stepYears: Double = 1.0
    ) -> Projection {
        let principal = max(0, principal)
        let monthlyContribution = max(0, monthlyContribution)
        let rate = max(0, annualRate)
        let inflation = max(0, annualInflation)
        let years = max(0, years)
        let step = stepYears > 0 ? stepYears : 1.0

        func point(at t: Double) -> ProjectionPoint {
            let nominal = futureValue(
                principal: principal,
                annualRate: rate,
                years: t,
                compounding: compounding
            ) + futureValueOfAnnuity(
                monthlyPayment: monthlyContribution,
                annualRate: rate,
                years: t,
                compounding: compounding
            )
            let contributions = principal + monthlyContribution * 12 * t
            let growth = max(0, nominal - contributions)
            let real = realValue(nominal: nominal, annualInflation: inflation, years: t)
            return ProjectionPoint(
                years: t,
                nominal: nominal,
                real: real,
                contributions: contributions,
                growth: growth
            )
        }

        var points: [ProjectionPoint] = []
        if years > 0 {
            let stepCount = Int(ceil(years / step))
            for k in 0..<stepCount {
                points.append(point(at: Double(k) * step))
            }
        }
        let final = point(at: years)
        points.append(final)

        return Projection(
            points: points,
            finalNominal: final.nominal,
            finalReal: final.real,
            totalContributions: final.contributions,
            totalGrowth: final.growth
        )
    }

    // MARK: - Side-by-side comparison

    /// The difference between two projections over the same horizon, so the
    /// UI can show two paths together (for example, cash vs invested, or
    /// spending vs redirecting). Positive means the first path ends higher.
    public struct Comparison: Equatable, Sendable {
        public var first: Projection
        public var second: Projection
        public var differenceNominal: Double
        public var differenceReal: Double

        public init(first: Projection, second: Projection) {
            self.first = first
            self.second = second
            self.differenceNominal = first.finalNominal - second.finalNominal
            self.differenceReal = first.finalReal - second.finalReal
        }
    }

    public static func compare(_ first: Projection, _ second: Projection) -> Comparison {
        Comparison(first: first, second: second)
    }
}
