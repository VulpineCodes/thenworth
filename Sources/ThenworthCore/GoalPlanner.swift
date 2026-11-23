import Foundation

/// Plans toward a savings goal: how much will be there on the target date,
/// how much is still missing, and how long reaching the target takes.
public enum GoalPlanner {

    /// The longest horizon considered when searching for a reachable date:
    /// 100 years (1,200 months). Beyond that the goal is unreachable.
    public static let maxMonthsToGoal = 1_200

    public static func plan(
        target: Double,
        currentSavings: Double,
        monthlyRedirect: Double,
        annualRate: Double,
        annualInflation: Double,
        targetMonths: Int,
        compounding: CompoundingFrequency
    ) -> GoalResult {
        let target = max(0, target)
        let currentSavings = max(0, currentSavings)
        let monthlyRedirect = max(0, monthlyRedirect)
        let rate = max(0, annualRate)
        let inflation = max(0, annualInflation)
        let targetMonths = max(0, targetMonths)
        let yearsToTarget = Double(targetMonths) / 12

        let projected = FinancialEngine.futureValue(
            principal: currentSavings,
            annualRate: rate,
            years: yearsToTarget,
            compounding: compounding
        ) + FinancialEngine.futureValueOfAnnuity(
            monthlyPayment: monthlyRedirect,
            annualRate: rate,
            years: yearsToTarget,
            compounding: compounding
        )
        let projectedReal = FinancialEngine.realValue(
            nominal: projected,
            annualInflation: inflation,
            years: yearsToTarget
        )
        let shortfall = max(0, target - projected)
        let onTrack = projected >= target

        let monthsToGoal: Int?
        if target <= currentSavings {
            monthsToGoal = 0
        } else {
            monthsToGoal = monthsUntilGoal(
                target: target,
                currentSavings: currentSavings,
                monthlyRedirect: monthlyRedirect,
                annualRate: rate,
                compounding: compounding
            )
        }

        return GoalResult(
            target: target,
            currentSavings: currentSavings,
            monthlyRedirect: monthlyRedirect,
            targetMonths: targetMonths,
            projectedAtTargetDate: projected,
            projectedRealAtTargetDate: projectedReal,
            shortfall: shortfall,
            onTrack: onTrack,
            monthsToGoal: monthsToGoal
        )
    }

    /// Smallest whole number of months for the balance to reach the target,
    /// or nil when it cannot within 100 years.
    private static func monthsUntilGoal(
        target: Double,
        currentSavings: Double,
        monthlyRedirect: Double,
        annualRate: Double,
        compounding: CompoundingFrequency
    ) -> Int? {
        for months in 1...maxMonthsToGoal {
            let years = Double(months) / 12
            let value = FinancialEngine.futureValue(
                principal: currentSavings,
                annualRate: annualRate,
                years: years,
                compounding: compounding
            ) + FinancialEngine.futureValueOfAnnuity(
                monthlyPayment: monthlyRedirect,
                annualRate: annualRate,
                years: years,
                compounding: compounding
            )
            if value >= target {
                return months
            }
        }
        return nil
    }
}
