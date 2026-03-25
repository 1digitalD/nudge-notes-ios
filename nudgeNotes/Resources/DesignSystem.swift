import SwiftUI

// MARK: - Color Hex Extension
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r, g, b: UInt64
        switch hex.count {
        case 6:
            (r, g, b) = ((int >> 16) & 0xFF, (int >> 8) & 0xFF, int & 0xFF)
        default:
            (r, g, b) = (0, 0, 0)
        }
        self.init(
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255
        )
    }
}

// MARK: - Named Colors (light/dark adaptive via Assets.xcassets)
extension Color {
    static let appBackground = Color("AppBackground")
    static let appCard = Color("AppCard")
    static let appText = Color("AppText")
    static let appTextSecondary = Color("AppTextSecondary")
    static let appAccent = Color("AppAccent")
    static let appBorder = Color("AppBorder")

    // Semantic status colors (adaptive light/dark)
    static let appSuccess = Color("AppSuccess")
    static let appWarning = Color("AppWarning")
    static let appDanger = Color("AppDanger")
    static let appTeal = Color("AppTeal")
    static let appMint = Color("AppMint")
}

// MARK: - App Colors (explicit hex values, use for preview/non-adaptive)
struct AppColors {
    // Light mode (extracted from PDF journal)
    static let background = Color(hex: "#FFFFFF")
    static let backgroundAlt = Color(hex: "#FEFEFE")
    static let cardBackground = Color.white
    static let text = Color(hex: "#424242")
    static let textSecondary = Color(hex: "#7A7A7A")
    static let textTertiary = Color(hex: "#B5B5B5")

    static let accentBlue = Color(hex: "#0049AC")
    static let accentTeal = Color(hex: "#58BBCC")
    static let accentMint = Color(hex: "#BAEDD5")
    static let accentSkyBlue = Color(hex: "#B2DFE7")

    static let border = Color(hex: "#E2E2E2")
    static let divider = Color(hex: "#EAEAEA")

    // Dark mode
    static let darkBackground = Color(hex: "#000000")
    static let darkBackgroundAlt = Color(hex: "#1C1C1E")
    static let darkCardBackground = Color(hex: "#2C2C2E")
    static let darkText = Color(hex: "#FFFFFF")
    static let darkTextSecondary = Color(hex: "#98989D")
    static let darkTextTertiary = Color(hex: "#636366")

    static let darkAccentBlue = Color(hex: "#0A84FF")
    static let darkAccentTeal = Color(hex: "#64D2FF")
    static let darkAccentMint = Color(hex: "#63E6BE")
    static let darkAccentSkyBlue = Color(hex: "#5AC8FA")

    static let darkBorder = Color(hex: "#38383A")
    static let darkDivider = Color(hex: "#2C2C2E")
}

// MARK: - Typography
struct AppFonts {
    static let largeTitle = Font.system(size: 34, weight: .bold)
    static let title = Font.system(size: 28, weight: .semibold)
    static let headline = Font.system(size: 20, weight: .semibold)
    static let body = Font.system(size: 17, weight: .regular)
    static let bodyEmphasized = Font.system(size: 17, weight: .medium)
    static let caption = Font.system(size: 15, weight: .regular)
    static let captionEmphasized = Font.system(size: 15, weight: .semibold)
    static let footnote = Font.system(size: 13, weight: .regular)
}

// MARK: - Spacing
struct AppSpacing {
    static let xs: CGFloat = 6
    static let sm: CGFloat = 10
    static let md: CGFloat = 16
    static let lg: CGFloat = 24
    static let xl: CGFloat = 32
    static let xxl: CGFloat = 48

    static let cornerRadius: CGFloat = 16
    static let cardPadding: CGFloat = 18
    static let sectionSpacing: CGFloat = 24
    static let screenPadding: CGFloat = 20
}

// MARK: - Animation
struct AppAnimation {
    static let spring = Animation.spring(response: 0.3, dampingFraction: 0.7)
    static let springLight = Animation.spring(response: 0.25, dampingFraction: 0.8)
}
