import Foundation
import XCTest
import ThenworthCore

/// Shared fixtures and helpers for ThenworthCore tests.
///
/// Expected values in these tests were computed independently in Python
/// (python3, `math` module) with the closed-form formulas, not by running
/// the Swift code under test. Each test cites its independent source.

enum TestFixtures {
    static let monthly = CompoundingFrequency.monthly
    static let annual = CompoundingFrequency.annually
    static let quarterly = CompoundingFrequency.quarterly
    static let daily = CompoundingFrequency.daily

    static func roundTrip<T: Codable & Equatable>(_ value: T) throws -> T {
        let data = try JSONEncoder().encode(value)
        return try JSONDecoder().decode(T.self, from: data)
    }
}

extension XCTestCase {
    /// Asserts two dollar amounts agree to within the given tolerance
    /// (default: 1 cent).
    func assertDollarsEqual(
        _ actual: Double,
        _ expected: Double,
        accuracy: Double = 0.01,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        XCTAssertEqual(actual, expected, accuracy: accuracy, file: file, line: line)
    }
}
