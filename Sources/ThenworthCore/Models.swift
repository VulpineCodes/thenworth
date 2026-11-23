import Foundation

/// How often interest compounds within a year.
public enum CompoundingFrequency: String, CaseIterable, Codable, Sendable {
    case annually
    case quarterly
    case monthly
    case daily

    /// Compounding periods per year.
    public var periodsPerYear: Double {
        switch self {
        case .annually: return 1
        case .quarterly: return 4
        case .monthly: return 12
        case .daily: return 365
        }
    }
}

/// The shared assumptions behind a projection.
///
/// All returns are hypothetical. Nothing here is a guarantee of future
/// performance; the app layer must label projected growth as hypothetical.
public struct Assumptions: Codable, Equatable, Sendable {
    /// Hypothetical annual return, as a decimal (0.07 is 7 percent).
    public var annualReturn: Double
    /// Annual inflation, as a decimal (0.03 is 3 percent).
    public var annualInflation: Double
    public var compounding: CompoundingFrequency

    public init(annualReturn: Double, annualInflation: Double, compounding: CompoundingFrequency) {
        self.annualReturn = max(0, annualReturn)
        self.annualInflation = max(0, annualInflation)
        self.compounding = compounding
    }

    /// Invested savings: 7 percent hypothetical annual return, 3 percent inflation.
    public static let `default` = Assumptions(
        annualReturn: 0.07,
        annualInflation: 0.03,
        compounding: .monthly
    )

    /// Cash savings: 0 percent return, 3 percent inflation.
    public static let cash = Assumptions(
        annualReturn: 0.0,
        annualInflation: 0.03,
        compounding: .monthly
    )
}

/// One point on a projection curve.
public struct ProjectionPoint: Equatable, Sendable {
    /// Years from today.
    public var years: Double
    /// Value in future dollars at this point.
    public var nominal: Double
    /// Value in today's dollars at this point (inflation-adjusted).
    public var real: Double
    /// Total money put in by this point (principal plus contributions).
    public var contributions: Double
    /// Nominal value minus contributions: the hypothetical growth.
    public var growth: Double

    public init(years: Double, nominal: Double, real: Double, contributions: Double, growth: Double) {
        self.years = years
        self.nominal = nominal
        self.real = real
        self.contributions = contributions
        self.growth = growth
    }
}

/// A full projection over a horizon, sampled at regular steps.
public struct Projection: Equatable, Sendable {
    public var points: [ProjectionPoint]
    public var finalNominal: Double
    public var finalReal: Double
    public var totalContributions: Double
    public var totalGrowth: Double

    public init(points: [ProjectionPoint], finalNominal: Double, finalReal: Double, totalContributions: Double, totalGrowth: Double) {
        self.points = points
        self.finalNominal = finalNominal
        self.finalReal = finalReal
        self.totalContributions = totalContributions
        self.totalGrowth = totalGrowth
    }
}

/// The outcome of planning toward a savings goal.
public struct GoalResult: Equatable, Sendable {
    public var target: Double
    public var currentSavings: Double
    public var monthlyRedirect: Double
    /// Target date, in months from today.
    public var targetMonths: Int
    /// Projected nominal value on the target date.
    public var projectedAtTargetDate: Double
    /// Projected value on the target date, in today's dollars.
    public var projectedRealAtTargetDate: Double
    /// Amount still missing on the target date (0 when on track).
    public var shortfall: Double
    /// True when the projected value on the target date meets the target.
    public var onTrack: Bool
    /// Months needed to reach the target, or nil if unreachable within 100 years.
    public var monthsToGoal: Int?

    public init(
        target: Double,
        currentSavings: Double,
        monthlyRedirect: Double,
        targetMonths: Int,
        projectedAtTargetDate: Double,
        projectedRealAtTargetDate: Double,
        shortfall: Double,
        onTrack: Bool,
        monthsToGoal: Int?
    ) {
        self.target = target
        self.currentSavings = currentSavings
        self.monthlyRedirect = monthlyRedirect
        self.targetMonths = targetMonths
        self.projectedAtTargetDate = projectedAtTargetDate
        self.projectedRealAtTargetDate = projectedRealAtTargetDate
        self.shortfall = shortfall
        self.onTrack = onTrack
        self.monthsToGoal = monthsToGoal
    }
}

/// One side of a retirement start-early vs start-late comparison.
public struct RetirementSide: Equatable, Sendable {
    public var startAge: Int
    /// Total money the person contributed themselves.
    public var contributions: Double
    /// Total employer match received.
    public var employerMatch: Double
    /// Hypothetical growth (final value minus all contributions and match).
    public var growth: Double
    public var finalNominal: Double
    /// Final value in today's dollars.
    public var finalReal: Double

    public init(
        startAge: Int,
        contributions: Double,
        employerMatch: Double,
        growth: Double,
        finalNominal: Double,
        finalReal: Double
    ) {
        self.startAge = startAge
        self.contributions = contributions
        self.employerMatch = employerMatch
        self.growth = growth
        self.finalNominal = finalNominal
        self.finalReal = finalReal
    }
}

/// A side-by-side retirement comparison: starting early vs starting late.
public struct RetirementComparison: Equatable, Sendable {
    public var early: RetirementSide
    public var late: RetirementSide
    /// Early final nominal minus late final nominal.
    public var differenceNominal: Double
    /// Early final real minus late final real.
    public var differenceReal: Double

    public init(early: RetirementSide, late: RetirementSide, differenceNominal: Double, differenceReal: Double) {
        self.early = early
        self.late = late
        self.differenceNominal = differenceNominal
        self.differenceReal = differenceReal
    }
}

/// The kind of financial question a saved scenario answers.
public enum ScenarioKind: String, Codable, CaseIterable, Sendable {
    case oneTime
    case recurring
    case goal
    case retirement
}

/// The inputs behind a saved scenario. Only the fields relevant to the
/// scenario's kind are set; the rest are nil.
public struct ScenarioInputs: Codable, Equatable, Sendable {
    public var kind: ScenarioKind
    public var amount: Double?
    public var monthlyAmount: Double?
    public var years: Double?
    public var targetAmount: Double?
    public var currentSavings: Double?
    public var monthlyRedirect: Double?
    public var targetMonths: Int?
    public var earlyStartAge: Int?
    public var lateStartAge: Int?
    public var retirementAge: Int?
    public var monthlyContribution: Double?
    public var employerMatchRate: Double?
    public var employerMatchCapMonthly: Double?
    public var assumptions: Assumptions

    public init(
        kind: ScenarioKind,
        amount: Double? = nil,
        monthlyAmount: Double? = nil,
        years: Double? = nil,
        targetAmount: Double? = nil,
        currentSavings: Double? = nil,
        monthlyRedirect: Double? = nil,
        targetMonths: Int? = nil,
        earlyStartAge: Int? = nil,
        lateStartAge: Int? = nil,
        retirementAge: Int? = nil,
        monthlyContribution: Double? = nil,
        employerMatchRate: Double? = nil,
        employerMatchCapMonthly: Double? = nil,
        assumptions: Assumptions = .default
    ) {
        self.kind = kind
        self.amount = amount.map { max(0, $0) }
        self.monthlyAmount = monthlyAmount.map { max(0, $0) }
        self.years = years.map { max(0, $0) }
        self.targetAmount = targetAmount.map { max(0, $0) }
        self.currentSavings = currentSavings.map { max(0, $0) }
        self.monthlyRedirect = monthlyRedirect.map { max(0, $0) }
        self.targetMonths = targetMonths.map { max(0, $0) }
        self.earlyStartAge = earlyStartAge.map { max(0, $0) }
        self.lateStartAge = lateStartAge.map { max(0, $0) }
        self.retirementAge = retirementAge.map { max(0, $0) }
        self.monthlyContribution = monthlyContribution.map { max(0, $0) }
        self.employerMatchRate = employerMatchRate.map { max(0, $0) }
        self.employerMatchCapMonthly = employerMatchCapMonthly.map { max(0, $0) }
        self.assumptions = assumptions
    }
}

/// A user-saved scenario: a named question with its inputs.
public struct SavedScenario: Codable, Identifiable, Equatable, Sendable {
    public var id: UUID
    public var kind: ScenarioKind
    public var title: String
    public var inputs: ScenarioInputs
    public var createdAt: Date
    public var updatedAt: Date

    public init(
        id: UUID,
        kind: ScenarioKind,
        title: String,
        inputs: ScenarioInputs,
        createdAt: Date,
        updatedAt: Date
    ) {
        self.id = id
        self.kind = kind
        self.title = title
        self.inputs = inputs
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    /// Convenience initializer for a new scenario: fresh id, now timestamps.
    public init(kind: ScenarioKind, title: String, inputs: ScenarioInputs) {
        let now = Date()
        self.init(
            id: UUID(),
            kind: kind,
            title: title,
            inputs: inputs,
            createdAt: now,
            updatedAt: now
        )
    }
}
