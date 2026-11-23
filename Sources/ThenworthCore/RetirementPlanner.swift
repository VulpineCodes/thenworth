import Foundation

/// Compares starting retirement saving early vs starting late, keeping the
/// person's own contributions, the employer match, and hypothetical growth
/// as separate figures.
public enum RetirementPlanner {

    public static func compare(
        earlyStartAge: Int,
        lateStartAge: Int,
        retirementAge: Int,
        monthlyContribution: Double,
        annualReturn: Double,
        annualInflation: Double,
        employerMatchRate: Double,
        employerMatchCapMonthly: Double,
        compounding: CompoundingFrequency
    ) -> RetirementComparison {
        let monthlyContribution = max(0, monthlyContribution)
        let annualReturn = max(0, annualReturn)
        let annualInflation = max(0, annualInflation)
        let matchRate = max(0, employerMatchRate)
        let matchCap = max(0, employerMatchCapMonthly)

        let early = side(
            startAge: max(0, earlyStartAge),
            retirementAge: max(0, retirementAge),
            monthlyContribution: monthlyContribution,
            annualReturn: annualReturn,
            annualInflation: annualInflation,
            matchRate: matchRate,
            matchCap: matchCap,
            compounding: compounding
        )
        let late = side(
            startAge: max(0, lateStartAge),
            retirementAge: max(0, retirementAge),
            monthlyContribution: monthlyContribution,
            annualReturn: annualReturn,
            annualInflation: annualInflation,
            matchRate: matchRate,
            matchCap: matchCap,
            compounding: compounding
        )

        return RetirementComparison(
            early: early,
            late: late,
            differenceNominal: early.finalNominal - late.finalNominal,
            differenceReal: early.finalReal - late.finalReal
        )
    }

    private static func side(
        startAge: Int,
        retirementAge: Int,
        monthlyContribution: Double,
        annualReturn: Double,
        annualInflation: Double,
        matchRate: Double,
        matchCap: Double,
        compounding: CompoundingFrequency
    ) -> RetirementSide {
        let years = max(0, retirementAge - startAge)
        let months = Double(years * 12)
        // Employer match per month: a percentage of the person's
        // contribution, capped at the monthly cap.
        let monthlyMatch = min(monthlyContribution * matchRate, matchCap)
        let totalMonthly = monthlyContribution + monthlyMatch

        let finalNominal = FinancialEngine.futureValueOfAnnuity(
            monthlyPayment: totalMonthly,
            annualRate: annualReturn,
            years: Double(years),
            compounding: compounding
        )
        let contributions = monthlyContribution * months
        let employerMatch = monthlyMatch * months
        let growth = max(0, finalNominal - contributions - employerMatch)
        let finalReal = FinancialEngine.realValue(
            nominal: finalNominal,
            annualInflation: annualInflation,
            years: Double(years)
        )

        return RetirementSide(
            startAge: startAge,
            contributions: contributions,
            employerMatch: employerMatch,
            growth: growth,
            finalNominal: finalNominal,
            finalReal: finalReal
        )
    }
}
