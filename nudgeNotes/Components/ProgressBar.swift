import SwiftUI

struct ProgressBar: View {
    let current: Double
    let goal: Double

    var progress: Double { goal > 0 ? min(current / goal, 1.0) : 0 }

    var barColor: Color {
        switch progress {
        case 1.0...: return Color(hex: "#4CAF50")  // Green — goal met
        case 0.5...: return AppTheme.accent          // Blue — halfway+
        default:     return Color.gray.opacity(0.5)  // Gray — under 50%
        }
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Rectangle()
                    .fill(Color.gray.opacity(0.15))
                    .frame(width: geometry.size.width, height: 4)

                Rectangle()
                    .fill(barColor)
                    .frame(width: geometry.size.width * progress, height: 4)
                    .animation(.easeOut(duration: 0.3), value: progress)
            }
            .clipShape(RoundedRectangle(cornerRadius: 2))
            .frame(height: 4)
        }
        .frame(height: 4)
    }
}

/// Compact progress label: "4/8 glasses · 50%"
struct ProgressLabel: View {
    let current: Double
    let goal: Double
    let unit: String

    var percentage: Int { goal > 0 ? Int((current / goal * 100).rounded()) : 0 }

    var body: some View {
        HStack(spacing: 4) {
            Text("\(formatValue(current))/\(formatValue(goal)) \(unit)")
                .font(.caption2)
                .foregroundStyle(.secondary)
            Text("·")
                .font(.caption2)
                .foregroundStyle(.secondary)
            Text("\(min(percentage, 100))%")
                .font(.caption2.weight(.medium))
                .foregroundStyle(percentage >= 100 ? Color(hex: "#4CAF50") : .secondary)
        }
    }

    private func formatValue(_ v: Double) -> String {
        v == v.rounded() ? String(Int(v)) : String(format: "%.1f", v)
    }
}
