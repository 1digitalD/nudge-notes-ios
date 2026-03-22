import SwiftUI

enum AppTheme {
    static let accent = Color(
        uiColor: UIColor { traits in
            traits.userInterfaceStyle == .dark
                ? UIColor(red: 181 / 255, green: 199 / 255, blue: 166 / 255, alpha: 1)
                : UIColor(red: 140 / 255, green: 160 / 255, blue: 122 / 255, alpha: 1)
        }
    )

    static let background = Color(
        uiColor: UIColor { traits in
            traits.userInterfaceStyle == .dark
                ? UIColor(red: 22 / 255, green: 27 / 255, blue: 24 / 255, alpha: 1)
                : UIColor(red: 245 / 255, green: 241 / 255, blue: 232 / 255, alpha: 1)
        }
    )

    static let cardBackground = Color(.secondarySystemGroupedBackground)
}
