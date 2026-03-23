import SwiftUI

enum AppTheme {
    // Primary brand colors (from PDF design)
    static let nudgeBlue = Color(hex: "#2B7FDB")
    static let mint = Color(hex: "#7DD3C0")
    
    // Core colors (PDF-aligned)
    static let accent = Color(hex: "#2B7FDB")  // Blue from PDF
    static let background = Color(hex: "#FAFAFA")  // Light background
    static let cardBackground = Color.white.opacity(0.95)  // Clean white cards
    static let paper = Color(hex: "#F5F5F5")  // Subtle gray
    static let ink = Color(hex: "#1A1A1A")  // Dark text
    static let divider = Color(hex: "#E0E0E0")  // Subtle dividers
}

// MARK: - Hex Color Extension
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r, g, b: UInt64
        switch hex.count {
        case 6: // RGB
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
