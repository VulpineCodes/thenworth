import XCTest
import ThenworthCore

/// Expected values below were computed independently in Python:
///   100*(1+0.07/12)**240, 100*(1+0.07)**20, 100*(1+0.07/4)**80,
///   100*(1+0.07/365)**7300, 100*(((1+0.07/12)**240-1)/(0.07/12)),
///   10000/(1.03**20), and the matching closed forms.
final class FinancialEngineTests: XCTestCase {

    // MARK: - Future value of a lump sum

    func testFutureValueMonthlyCompounding() {
        // Python: 100*(1+0.07/12)**(12*20) = 403.87
        assertDollarsEqual(
            FinancialEngine.futureValue(principal: 100, annualRate: 0.07, years: 20, compounding: .monthly),
            403.87
        )
    }

    func testFutureValueAnnualCompounding() {
        // Python: 100*(1+0.07)**20 = 386.97
        assertDollarsEqual(
            FinancialEngine.futureValue(principal: 100, annualRate: 0.07, years: 20, compounding: .annually),
            386.97
        )
    }

    func testFutureValueQuarterlyCompounding() {
        // Python: 100*(1+0.07/4)**(4*20) = 400.64
        assertDollarsEqual(
            FinancialEngine.futureValue(principal: 100, annualRate: 0.07, years: 20, compounding: .quarterly),
            400.64
        )
    }

    func testFutureValueDailyCompounding() {
        // Python: 100*(1+0.07/365)**(365*20) = 405.47
        assertDollarsEqual(
            FinancialEngine.futureValue(principal: 100, annualRate: 0.07, years: 20, compounding: .daily),
            405.47
        )
    }

    func testMoreFrequentCompoundingGrowsFaster() {
        let annual = FinancialEngine.futureValue(principal: 100, annualRate: 0.07, years: 20, compounding: .annually)
        let quarterly = FinancialEngine.futureValue(principal: 100, annualRate: 0.07, years: 20, compounding: .quarterly)
        let monthly = FinancialEngine.futureValue(principal: 100, annualRate: 0.07, years: 20, compounding: .monthly)
        let daily = FinancialEngine.futureValue(principal: 100, annualRate: 0.07, years: 20, compounding: .daily)
        XCTAssertLessThan(annual, quarterly)
        XCTAssertLessThan(quarterly, monthly)
        XCTAssertLessThan(monthly, daily)
    }

    // MARK: - Future value of an annuity

    func testAnnuityMonthlyCompounding() {
        // Python: 100*(((1+0.07/12)**240-1)/(0.07/12)) = 52092.67
        assertDollarsEqual(
            FinancialEngine.futureValueOfAnnuity(monthlyPayment: 100, annualRate: 0.07, years: 20, compounding: .monthly),
            52_092.67
        )
    }

    func testAnnuityAnnualCompounding() {
        // Python: i=(1.07)**(1/12)-1; 100*(((1+i)**240-1)/i) = 50753.64
        assertDollarsEqual(
            FinancialEngine.futureValueOfAnnuity(monthlyPayment: 100, annualRate: 0.07, years: 20, compounding: .annually),
            50_753.64
        )
    }

    func testAnnuityZeroRateIsPlainSum() {
        // 100/month for 20 years with no return: 100 * 240 = 24000
        assertDollarsEqual(
            FinancialEngine.futureValueOfAnnuity(monthlyPayment: 100, annualRate: 0, years: 20, compounding: .monthly),
            24_000
        )
    }

    // MARK: - Inflation adjustment

    func testRealValue() {
        // Python: 10000/(1.03**20) = 5536.76
        assertDollarsEqual(
            FinancialEngine.realValue(nominal: 10_000, annualInflation: 0.03, years: 20),
            5_536.76
        )
    }

    func testRealValueOfFutureValue() {
        // Python: 403.87/(1.03**20) = 223.62: $100 at 7% for 20 years is
        // $403.87 in future dollars but only $223.62 in today's dollars.
        let nominal = FinancialEngine.futureValue(principal: 100, annualRate: 0.07, years: 20, compounding: .monthly)
        assertDollarsEqual(
            FinancialEngine.realValue(nominal: nominal, annualInflation: 0.03, years: 20),
            223.62
        )
    }

    func testRealValueZeroInflationIsNominal() {
        XCTAssertEqual(
            FinancialEngine.realValue(nominal: 10_000, annualInflation: 0, years: 20),
            10_000
        )
    }

    // MARK: - Recurring costs and redirecting them

    func testTotalPaid() {
        // $2.88/month for 20 years: 2.88 * 12 * 20 = 691.20
        assertDollarsEqual(FinancialEngine.totalPaid(monthlyAmount: 2.88, years: 20), 691.20)
        assertDollarsEqual(FinancialEngine.totalPaid(monthlyAmount: 100, years: 20), 24_000)
    }

    func testRedirectedSmallSubscriptionAccumulates() {
        // Python: 2.88*(((1+0.07/12)**240-1)/(0.07/12)) = 1500.27.
        // Redirecting a $2.88/month subscription at 7% for 20 years grows
        // $691.20 of payments into $1,500.27.
        assertDollarsEqual(
            FinancialEngine.redirectedValue(monthlyAmount: 2.88, annualRate: 0.07, years: 20, compounding: .monthly),
            1_500.27
        )
    }

    func testCashVsInvestedDivergence() {
        // $100/month for 20 years: cash is the plain sum, 24000.
        // Invested at 7% monthly compounding: 52092.67 (Python, above).
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
        assertDollarsEqual(cash.finalNominal, 24_000)
        assertDollarsEqual(cash.totalGrowth, 0)
        assertDollarsEqual(invested.finalNominal, 52_092.67)
        XCTAssertGreaterThan(invested.finalNominal, cash.finalNominal)
        // Cash loses purchasing power: 24000 in 20 years at 3% inflation.
        // Python: 24000/(1.03**20) = 13288.22
        assertDollarsEqual(cash.finalReal, 13_288.22)
    }

    // MARK: - Edge cases

    func testZeroPrincipalZeroRateZeroYears() {
        XCTAssertEqual(
            FinancialEngine.futureValue(principal: 0, annualRate: 0.07, years: 20, compounding: .monthly), 0)
        XCTAssertEqual(
            FinancialEngine.futureValue(principal: 100, annualRate: 0, years: 20, compounding: .monthly), 100)
        XCTAssertEqual(
            FinancialEngine.futureValue(principal: 100, annualRate: 0.07, years: 0, compounding: .monthly), 100)
        XCTAssertEqual(
            FinancialEngine.futureValueOfAnnuity(monthlyPayment: 0, annualRate: 0.07, years: 20, compounding: .monthly), 0)
        XCTAssertEqual(
            FinancialEngine.futureValueOfAnnuity(monthlyPayment: 100, annualRate: 0.07, years: 0, compounding: .monthly), 0)
        XCTAssertEqual(FinancialEngine.totalPaid(monthlyAmount: 100, years: 0), 0)
    }

    func testNegativeInputsClampToZero() {
        XCTAssertEqual(
            FinancialEngine.futureValue(principal: -100, annualRate: 0.07, years: 20, compounding: .monthly), 0)
        XCTAssertEqual(
            FinancialEngine.futureValue(principal: 100, annualRate: -0.07, years: 20, compounding: .monthly), 100)
        XCTAssertEqual(
            FinancialEngine.futureValue(principal: 100, annualRate: 0.07, years: -5, compounding: .monthly), 100)
        XCTAssertEqual(
            FinancialEngine.futureValueOfAnnuity(monthlyPayment: -100, annualRate: 0.07, years: 20, compounding: .monthly), 0)
        XCTAssertEqual(FinancialEngine.totalPaid(monthlyAmount: -50, years: 20), 0)
        XCTAssertEqual(FinancialEngine.realValue(nominal: -100, annualInflation: 0.03, years: 20), 0)
    }

    func testHundredYearHorizonIsFinite() {
        // Python: 100*(1+0.07/12)**1200 = 107455.55
        // Python: 100*(((1+0.07/12)**1200-1)/(0.07/12)) = 18403808.92
        let lump = FinancialEngine.futureValue(principal: 100, annualRate: 0.07, years: 100, compounding: .monthly)
        assertDollarsEqual(lump, 107_455.55, accuracy: 1.0)
        XCTAssertTrue(lump.isFinite)
        let annuity = FinancialEngine.futureValueOfAnnuity(monthlyPayment: 100, annualRate: 0.07, years: 100, compounding: .monthly)
        assertDollarsEqual(annuity, 18_403_808.92, accuracy: 1.0)
        XCTAssertTrue(annuity.isFinite)
        let projection = FinancialEngine.project(
            principal: 100, monthlyContribution: 100,
            annualRate: 0.07, annualInflation: 0.03, years: 100, compounding: .monthly
        )
        XCTAssertTrue(projection.finalNominal.isFinite)
        XCTAssertTrue(projection.finalReal.isFinite)
    }

    // MARK: - Projection shape

    func testProjectionFinalMatchesClosedForm() {
        // Python: FV 100 at 7% 20y monthly (403.87) + annuity 100/mo
        // (52092.67) = 52496.54 nominal; contributions 100 + 24000 = 24100;
        // growth 28396.54; real 52496.54/(1.03**20) = 29066.06.
        let projection = FinancialEngine.project(
            principal: 100, monthlyContribution: 100,
            annualRate: 0.07, annualInflation: 0.03, years: 20, compounding: .monthly
        )
        assertDollarsEqual(projection.finalNominal, 52_496.54)
        assertDollarsEqual(projection.totalContributions, 24_100)
        assertDollarsEqual(projection.totalGrowth, 28_396.54)
        assertDollarsEqual(projection.finalReal, 29_066.06)
    }

    func testProjectionPointsAreMonotonicAndCoverHorizon() {
        let projection = FinancialEngine.project(
            principal: 100, monthlyContribution: 100,
            annualRate: 0.07, annualInflation: 0.03, years: 20, compounding: .monthly
        )
        // Year 0 through year 20 inclusive, one point per year.
        XCTAssertEqual(projection.points.count, 21)
        XCTAssertEqual(projection.points.first?.years, 0)
        XCTAssertEqual(projection.points.last?.years, 20)
        XCTAssertEqual(projection.points.first?.nominal, 100)
        XCTAssertEqual(projection.points.first?.growth, 0)
        for index in 1..<projection.points.count {
            XCTAssertGreaterThanOrEqual(
                projection.points[index].nominal, projection.points[index - 1].nominal)
            XCTAssertGreaterThanOrEqual(
                projection.points[index].contributions, projection.points[index - 1].contributions)
        }
        XCTAssertEqual(projection.points.last?.nominal, projection.finalNominal)
        XCTAssertEqual(projection.points.last?.real, projection.finalReal)
        // Python: 10-year point: FV 100 (201.51) + annuity 100/mo
        // (17307.94) = 17509.45 nominal; contributions 12100;
        // real 17509.45/(1.03**10) = 13028.67.
        let tenYear = projection.points[10]
        assertDollarsEqual(tenYear.nominal, 17_509.45)
        assertDollarsEqual(tenYear.contributions, 12_100)
        assertDollarsEqual(tenYear.real, 13_028.67)
    }

    func testProjectionZeroYearsIsSinglePoint() {
        let projection = FinancialEngine.project(
            principal: 500, monthlyContribution: 100,
            annualRate: 0.07, annualInflation: 0.03, years: 0, compounding: .monthly
        )
        XCTAssertEqual(projection.points.count, 1)
        XCTAssertEqual(projection.finalNominal, 500)
        XCTAssertEqual(projection.finalReal, 500)
        XCTAssertEqual(projection.totalContributions, 500)
        XCTAssertEqual(projection.totalGrowth, 0)
    }

    func testProjectionHalfYearSteps() {
        let projection = FinancialEngine.project(
            principal: 0, monthlyContribution: 100,
            annualRate: 0.07, annualInflation: 0.03, years: 2, compounding: .monthly, stepYears: 0.5
        )
        XCTAssertEqual(projection.points.count, 5) // 0, 0.5, 1, 1.5, 2
        XCTAssertEqual(projection.points.map(\.years), [0, 0.5, 1, 1.5, 2])
    }

    // MARK: - Side-by-side comparison

    func testCompareCashVsInvested() {
        let cash = FinancialEngine.project(
            principal: 100, monthlyContribution: 100,
            annualRate: 0, annualInflation: 0.03, years: 20, compounding: .monthly
        )
        let invested = FinancialEngine.project(
            principal: 100, monthlyContribution: 100,
            annualRate: 0.07, annualInflation: 0.03, years: 20, compounding: .monthly
        )
        let comparison = FinancialEngine.compare(invested, cash)
        XCTAssertGreaterThan(comparison.differenceNominal, 0)
        XCTAssertGreaterThan(comparison.differenceReal, 0)
        // Python: invested 52496.54 minus cash 24100 = 28396.54.
        assertDollarsEqual(comparison.differenceNominal, 28_396.54)
    }

    // MARK: - Compounding frequency

    func testPeriodsPerYear() {
        XCTAssertEqual(CompoundingFrequency.annually.periodsPerYear, 1)
        XCTAssertEqual(CompoundingFrequency.quarterly.periodsPerYear, 4)
        XCTAssertEqual(CompoundingFrequency.monthly.periodsPerYear, 12)
        XCTAssertEqual(CompoundingFrequency.daily.periodsPerYear, 365)
        XCTAssertEqual(CompoundingFrequency.allCases.count, 4)
    }

    func testAssumptionsPresets() {
        XCTAssertEqual(Assumptions.default.annualReturn, 0.07)
        XCTAssertEqual(Assumptions.default.annualInflation, 0.03)
        XCTAssertEqual(Assumptions.default.compounding, .monthly)
        XCTAssertEqual(Assumptions.cash.annualReturn, 0)
        XCTAssertEqual(Assumptions.cash.annualInflation, 0.03)
        XCTAssertEqual(Assumptions.cash.compounding, .monthly)
    }
}
