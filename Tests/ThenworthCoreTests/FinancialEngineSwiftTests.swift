import Testing
import ThenworthCore

/// Swift Testing coverage for the ThenworthCore engine, in addition to the
/// XCTest suite (FinancialEngineTests, GoalPlannerTests,
/// RetirementPlannerTests, MilestonesTests, ModelsTests).
///
/// Expected values were computed independently in Python (closed-form
/// formulas), not by running the Swift code under test. Each test cites its
/// independent source, matching the values asserted in the XCTest suite.

private func close(_ actual: Double, _ expected: Double, tolerance: Double = 0.01) -> Bool {
    abs(actual - expected) <= tolerance
}

@Test("Future value: $100 at 7% for 20 years, monthly compounding")
func futureValueMonthlyCompounding() {
    // Python: 100*(1+0.07/12)**(12*20) = 403.87
    #expect(close(
        FinancialEngine.futureValue(principal: 100, annualRate: 0.07, years: 20, compounding: .monthly),
        403.87
    ))
}

@Test("Future value grows with compounding frequency")
func futureValueCompoundingOrder() {
    let annual = FinancialEngine.futureValue(principal: 100, annualRate: 0.07, years: 20, compounding: .annually)
    let quarterly = FinancialEngine.futureValue(principal: 100, annualRate: 0.07, years: 20, compounding: .quarterly)
    let monthly = FinancialEngine.futureValue(principal: 100, annualRate: 0.07, years: 20, compounding: .monthly)
    let daily = FinancialEngine.futureValue(principal: 100, annualRate: 0.07, years: 20, compounding: .daily)
    // Python: 386.97, 400.64, 403.87, 405.47
    #expect(close(annual, 386.97))
    #expect(close(quarterly, 400.64))
    #expect(close(monthly, 403.87))
    #expect(close(daily, 405.47))
    #expect(annual < quarterly && quarterly < monthly && monthly < daily)
}

@Test("Annuity: $100/month at 7% for 20 years")
func annuityMonthlyCompounding() {
    // Python: 100*(((1+0.07/12)**240-1)/(0.07/12)) = 52092.67
    #expect(close(
        FinancialEngine.futureValueOfAnnuity(monthlyPayment: 100, annualRate: 0.07, years: 20, compounding: .monthly),
        52_092.67
    ))
    // Zero rate is the plain sum: 100 * 240 = 24000.
    #expect(close(
        FinancialEngine.futureValueOfAnnuity(monthlyPayment: 100, annualRate: 0, years: 20, compounding: .monthly),
        24_000
    ))
}

@Test("Real value: inflation adjustment separates today's dollars from future dollars")
func realValueAdjustsForInflation() {
    // Python: 10000/(1.03**20) = 5536.76
    #expect(close(
        FinancialEngine.realValue(nominal: 10_000, annualInflation: 0.03, years: 20),
        5_536.76
    ))
    // Python: 403.87/(1.03**20) = 223.62
    let nominal = FinancialEngine.futureValue(principal: 100, annualRate: 0.07, years: 20, compounding: .monthly)
    #expect(close(
        FinancialEngine.realValue(nominal: nominal, annualInflation: 0.03, years: 20),
        223.62
    ))
    #expect(FinancialEngine.realValue(nominal: 10_000, annualInflation: 0, years: 20) == 10_000)
}

@Test("Cash vs invested: same contributions, different endings")
func cashVsInvestedDivergence() {
    let cash = FinancialEngine.project(
        principal: 0, monthlyContribution: 100,
        annualRate: Assumptions.cash.annualReturn,
        annualInflation: 0.03, years: 20, compounding: .monthly
    )
    let invested = FinancialEngine.project(
        principal: 0, monthlyContribution: 100,
        annualRate: Assumptions.default.annualReturn,
        annualInflation: 0.03, years: 20, compounding: .monthly
    )
    #expect(close(cash.finalNominal, 24_000))
    #expect(close(cash.totalGrowth, 0))
    // Python: invested annuity 52092.67
    #expect(close(invested.finalNominal, 52_092.67))
    #expect(invested.finalNominal > cash.finalNominal)
}

@Test("Projection final point matches the closed-form future value")
func projectionMatchesClosedForm() {
    // Python: 403.87 + 52092.67 = 52496.54 nominal; contributions 24100;
    // growth 28396.54; real 52496.54/(1.03**20) = 29066.06.
    let projection = FinancialEngine.project(
        principal: 100, monthlyContribution: 100,
        annualRate: 0.07, annualInflation: 0.03, years: 20, compounding: .monthly
    )
    #expect(close(projection.finalNominal, 52_496.54))
    #expect(close(projection.totalContributions, 24_100))
    #expect(close(projection.totalGrowth, 28_396.54))
    #expect(close(projection.finalReal, 29_066.06))
    #expect(projection.points.count == 21)
    for index in 1..<projection.points.count {
        #expect(projection.points[index].nominal >= projection.points[index - 1].nominal)
    }
}

@Test("Goal plan: car goal shortfall and months to goal")
func goalPlanShortfall() {
    // Python: projected 6860.92 at 24 months (1724.71 grown savings plus
    // 5136.21 annuity); shortfall 5139.08; first month reaching $12,000
    // is month 45.
    let result = GoalPlanner.plan(
        target: 12_000, currentSavings: 1_500, monthlyRedirect: 200,
        annualRate: 0.07, annualInflation: 0.03, targetMonths: 24, compounding: .monthly
    )
    #expect(close(result.projectedAtTargetDate, 6_860.92))
    #expect(close(result.shortfall, 5_139.08))
    #expect(result.onTrack == false)
    #expect(result.monthsToGoal == 45)
}

@Test("Goal plan: on-track goal has no shortfall")
func goalPlanOnTrack() {
    let result = GoalPlanner.plan(
        target: 6_000, currentSavings: 1_500, monthlyRedirect: 200,
        annualRate: 0.07, annualInflation: 0.03, targetMonths: 24, compounding: .monthly
    )
    #expect(result.onTrack == true)
    #expect(result.shortfall == 0)
    // Python: first month reaching $6,000 is month 21.
    #expect(result.monthsToGoal == 21)
}

@Test("Goal plan: unreachable goal reports nil months to goal")
func goalPlanUnreachable() {
    let result = GoalPlanner.plan(
        target: 12_000, currentSavings: 0, monthlyRedirect: 0,
        annualRate: 0, annualInflation: 0.03, targetMonths: 24, compounding: .monthly
    )
    #expect(result.projectedAtTargetDate == 0)
    #expect(result.onTrack == false)
    #expect(result.monthsToGoal == nil)
}

@Test("Retirement compare: starting at 23 beats starting at 30")
func retirementEarlyVsLate() {
    // Python: early 958767.79 nominal (151200 own + 7560 match +
    // 800007.79 growth), late 567332.20; difference 391435.59 nominal,
    // 75424.36 real.
    let comparison = RetirementPlanner.compare(
        earlyStartAge: 23, lateStartAge: 30, retirementAge: 65,
        monthlyContribution: 300, annualReturn: 0.07, annualInflation: 0.03,
        employerMatchRate: 0.05, employerMatchCapMonthly: 150, compounding: .monthly
    )
    #expect(close(comparison.early.finalNominal, 958_767.79))
    #expect(close(comparison.early.contributions, 151_200))
    #expect(close(comparison.early.employerMatch, 7_560))
    #expect(close(comparison.early.growth, 800_007.79))
    #expect(close(comparison.late.finalNominal, 567_332.20))
    #expect(close(comparison.differenceNominal, 391_435.59))
    #expect(close(comparison.differenceReal, 75_424.36))
    #expect(comparison.differenceNominal > 0)
    // The parts add up: match is money in, not growth.
    #expect(close(
        comparison.early.contributions + comparison.early.employerMatch + comparison.early.growth,
        comparison.early.finalNominal
    ))
}

@Test("Milestones translate amounts into concrete comparisons")
func milestoneTranslations() {
    #expect(Milestones.translation(for: 5) == nil)
    #expect(Milestones.translation(for: 40) == "about a dinner out")
    #expect(Milestones.translation(for: 200) == "about a month of groceries")
    #expect(Milestones.translation(for: 1_000) == "about a month of rent")
    #expect(Milestones.translation(for: 3_000) == "about 3 months of rent")
    #expect(Milestones.translation(for: 8_000) == "about a used car")
    #expect(Milestones.translation(for: 15_000) == "about a year of rent")
    #expect(Milestones.translation(for: 30_000) == "about a year of college tuition")
    #expect(Milestones.translation(for: 60_000) == "about a home down payment")
    #expect(Milestones.translation(for: 100_000) == "about a year of salary")
}

@Test("Edge cases: zero inputs, negative inputs, 100-year horizon")
func edgeCases() {
    #expect(FinancialEngine.futureValue(principal: 0, annualRate: 0.07, years: 20, compounding: .monthly) == 0)
    #expect(FinancialEngine.futureValue(principal: 100, annualRate: 0, years: 20, compounding: .monthly) == 100)
    #expect(FinancialEngine.futureValue(principal: 100, annualRate: 0.07, years: 0, compounding: .monthly) == 100)
    #expect(FinancialEngine.futureValue(principal: -100, annualRate: 0.07, years: 20, compounding: .monthly) == 0)
    #expect(FinancialEngine.futureValue(principal: 100, annualRate: -0.07, years: 20, compounding: .monthly) == 100)
    #expect(FinancialEngine.totalPaid(monthlyAmount: -50, years: 20) == 0)
    // Python: 100*(1+0.07/12)**1200 = 107455.55; finite, no overflow.
    let century = FinancialEngine.futureValue(principal: 100, annualRate: 0.07, years: 100, compounding: .monthly)
    #expect(close(century, 107_455.55, tolerance: 1.0))
    #expect(century.isFinite)
    // Python: 2.88*12*20 = 691.20 paid; redirected at 7% = 1500.27.
    #expect(close(FinancialEngine.totalPaid(monthlyAmount: 2.88, years: 20), 691.20))
    #expect(close(
        FinancialEngine.redirectedValue(monthlyAmount: 2.88, annualRate: 0.07, years: 20, compounding: .monthly),
        1_500.27
    ))
}

@Test("Assumptions presets carry the documented rates")
func assumptionsPresets() {
    #expect(Assumptions.default.annualReturn == 0.07)
    #expect(Assumptions.default.annualInflation == 0.03)
    #expect(Assumptions.default.compounding == .monthly)
    #expect(Assumptions.cash.annualReturn == 0)
    #expect(Assumptions.cash.annualInflation == 0.03)
    #expect(CompoundingFrequency.monthly.periodsPerYear == 12)
    #expect(CompoundingFrequency.daily.periodsPerYear == 365)
}
