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

// Hex Color extension defined in DesignSystem.swift
