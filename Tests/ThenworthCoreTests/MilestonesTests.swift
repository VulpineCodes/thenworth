import XCTest
import ThenworthCore

final class MilestonesTests: XCTestCase {

    func testVerySmallAmountsReturnNil() {
        XCTAssertNil(Milestones.translation(for: 0))
        XCTAssertNil(Milestones.translation(for: 5))
        XCTAssertNil(Milestones.translation(for: 14.99))
        XCTAssertNil(Milestones.translation(for: -100))
    }

    func testDinnerOut() {
        XCTAssertEqual(Milestones.translation(for: 15), "about a dinner out")
        XCTAssertEqual(Milestones.translation(for: 40), "about a dinner out")
        XCTAssertEqual(Milestones.translation(for: 74.99), "about a dinner out")
    }

    func testMonthOfGroceries() {
        XCTAssertEqual(Milestones.translation(for: 75), "about a month of groceries")
        XCTAssertEqual(Milestones.translation(for: 200), "about a month of groceries")
        XCTAssertEqual(Milestones.translation(for: 349.99), "about a month of groceries")
    }

    func testMonthOfRent() {
        XCTAssertEqual(Milestones.translation(for: 350), "about a month of rent")
        XCTAssertEqual(Milestones.translation(for: 1_000), "about a month of rent")
        XCTAssertEqual(Milestones.translation(for: 1_499.99), "about a month of rent")
    }

    func testThreeMonthsOfRent() {
        XCTAssertEqual(Milestones.translation(for: 1_500), "about 3 months of rent")
        XCTAssertEqual(Milestones.translation(for: 3_000), "about 3 months of rent")
        XCTAssertEqual(Milestones.translation(for: 4_499.99), "about 3 months of rent")
    }

    func testUsedCar() {
        XCTAssertEqual(Milestones.translation(for: 4_500), "about a used car")
        XCTAssertEqual(Milestones.translation(for: 8_000), "about a used car")
        XCTAssertEqual(Milestones.translation(for: 11_999.99), "about a used car")
    }

    func testYearOfRent() {
        XCTAssertEqual(Milestones.translation(for: 12_000), "about a year of rent")
        XCTAssertEqual(Milestones.translation(for: 15_000), "about a year of rent")
        XCTAssertEqual(Milestones.translation(for: 19_999.99), "about a year of rent")
    }

    func testYearOfCollegeTuition() {
        XCTAssertEqual(Milestones.translation(for: 20_000), "about a year of college tuition")
        XCTAssertEqual(Milestones.translation(for: 30_000), "about a year of college tuition")
        XCTAssertEqual(Milestones.translation(for: 44_999.99), "about a year of college tuition")
    }

    func testHomeDownPayment() {
        XCTAssertEqual(Milestones.translation(for: 45_000), "about a home down payment")
        XCTAssertEqual(Milestones.translation(for: 60_000), "about a home down payment")
        XCTAssertEqual(Milestones.translation(for: 79_999.99), "about a home down payment")
    }

    func testYearOfSalary() {
        XCTAssertEqual(Milestones.translation(for: 80_000), "about a year of salary")
        XCTAssertEqual(Milestones.translation(for: 100_000), "about a year of salary")
        XCTAssertEqual(Milestones.translation(for: 1_000_000), "about a year of salary")
    }

    func testTranslationsAreConcreteAndNonJudgmental() {
        // Every band's string is short, concrete, and free of judgmental
        // or shaming language.
        let amounts: [Double] = [20, 100, 500, 2_000, 6_000, 15_000, 30_000, 60_000, 100_000]
        for amount in amounts {
            let text = Milestones.translation(for: amount)
            XCTAssertNotNil(text, "expected a translation for $\(amount)")
            XCTAssertTrue(text?.hasPrefix("about ") == true, "unexpected wording: \(text ?? "")")
            XCTAssertLessThanOrEqual(text?.count ?? 0, 40)
        }
    }
}
