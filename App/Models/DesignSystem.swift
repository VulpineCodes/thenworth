import SwiftUI
import UIKit

// MARK: - Thenworth design system
//
// Green theme: deep forest green primary, warm ivory backgrounds, one
// bright growth-green accent. Deliberately NOT a neon fintech green.
// Every color below has a light and a dark variant. System fonts
// throughout, so Dynamic Type and VoiceOver keep working.
//
// NOTE: Written on the Linux VM; not compiled here. See App/README.md.

/// Hex helper for building dynamic colors.
private extension UIColor {
    convenience init(hex: String) {
        let cleaned = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var value: UInt64 = 0
        Scanner(string: cleaned).scanHexInt64(&value)
        let red = CGFloat((value >> 16) & 0xFF) / 255.0
        let green = CGFloat((value >> 8) & 0xFF) / 255.0
        let blue = CGFloat(value & 0xFF) / 255.0
        self.init(red: red, green: green, blue: blue, alpha: 1.0)
    }
}

private extension Color {
    /// A color with explicit light and dark variants.
    static func dynamic(lightHex: String, darkHex: String) -> Color {
        Color(uiColor: UIColor { traits in
            traits.userInterfaceStyle == .dark
                ? UIColor(hex: darkHex)
                : UIColor(hex: lightHex)
        })
    }
}

extension Color {
    /// Deep forest green. Primary brand color: buttons, selected states,
    /// the "let it grow" path.
    static let forestPrimary = Color.dynamic(lightHex: "1E4D38", darkHex: "8FC7A8")

    /// Darker forest, for headers and emphasis on light backgrounds.
    static let forestDeep = Color.dynamic(lightHex: "14382A", darkHex: "B7DCC6")

    /// One bright growth-green accent. Used sparingly: the growth line,
    /// the gap shading, positive deltas.
    static let growthAccent = Color.dynamic(lightHex: "2E8B57", darkHex: "4CC07A")

    /// Warm ivory app background (light) / deep green-black (dark).
    static let ivoryBackground = Color.dynamic(lightHex: "FAF6EC", darkHex: "111A14")

    /// Card surface: warm white (light) / lifted green-black (dark).
    static let cardSurface = Color.dynamic(lightHex: "FFFDF6", darkHex: "1D2B22")

    /// Soft border for cards and dividers.
    static let softBorder = Color.dynamic(lightHex: "E3DCCB", darkHex: "33473A")

    /// Muted text on ivory. System secondary is used where possible;
    /// this is for warm-toned secondary copy.
    static let warmMuted = Color.dynamic(lightHex: "5C665E", darkHex: "A8B5AB")
}

// MARK: - Type scale (system fonts, Dynamic Type friendly)

extension Font {
    /// Big display figure, e.g. the headline future value.
    static let thenworthDisplay = Font.system(.largeTitle, design: .rounded).weight(.bold)

    /// Screen titles.
    static let thenworthTitle = Font.system(.title2, design: .rounded).weight(.semibold)

    /// Section and card headings.
    static let thenworthHeadline = Font.system(.headline, design: .default).weight(.semibold)

    /// Body copy.
    static let thenworthBody = Font.system(.body, design: .default)

    /// Secondary copy, footnotes, "hypothetical" notes.
    static let thenworthCaption = Font.system(.subheadline, design: .default)

    /// Small labels and chips.
    static let thenworthFootnote = Font.system(.footnote, design: .default)
}

// MARK: - Spacing and radii

enum ThenworthSpace {
    static let xs: CGFloat = 4
    static let small: CGFloat = 8
    static let medium: CGFloat = 16
    static let large: CGFloat = 24
    static let xl: CGFloat = 32
}

enum ThenworthRadius {
    static let small: CGFloat = 10
    static let card: CGFloat = 16
    static let large: CGFloat = 24
}

// MARK: - Number and currency formatting

/// Single place for money formatting, so every screen agrees.
/// Amounts under $100 show cents (a $2.88 subscription matters);
/// larger amounts round to whole dollars.
enum MoneyFormat {
    static func currency(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        formatter.locale = Locale.current
        if abs(value) < 100 {
            formatter.minimumFractionDigits = 2
            formatter.maximumFractionDigits = 2
        } else {
            formatter.minimumFractionDigits = 0
            formatter.maximumFractionDigits = 0
        }
        return formatter.string(from: NSNumber(value: value)) ?? "$\(Int(value.rounded()))"
    }

    /// Whole dollars, always (for chart axes and compact labels).
    static func wholeDollars(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        formatter.locale = Locale.current
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: value)) ?? "$\(Int(value.rounded()))"
    }

    /// A rate stored as a fraction (0.07) rendered as "7%".
    static func percent(_ fraction: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .percent
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 1
        return formatter.string(from: NSNumber(value: fraction)) ?? "\(Int((fraction * 100).rounded()))%"
    }

    /// "20 years" / "1 year".
    static func yearsLabel(_ years: Double) -> String {
        let whole = Int(years.rounded())
        return whole == 1 ? "1 year" : "\(whole) years"
    }

    /// "18 months" / "1 month".
    static func monthsLabel(_ months: Int) -> String {
        months == 1 ? "1 month" : "\(months) months"
    }
}
