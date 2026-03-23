import SwiftUI

struct BodyMetricsSegmentView: View {
    @Bindable var dailyLog: DailyLog
    var onChanged: () -> Void

    @State private var weightText = ""
    @State private var waistText = ""
    @State private var hipsText = ""
    @State private var didLoadValues = false

    private var whr: Double? {
        guard let waist = dailyLog.waist, let hips = dailyLog.hips, hips > 0 else {
            return nil
        }
        return waist / hips
    }

    private var whrCategory: String? {
        guard let ratio = whr else { return nil }
        if ratio < 0.80 { return "Healthy" }
        if ratio < 0.85 { return "Moderate" }
        return "High"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Weight field
            metricRow(
                label: "Weight (lbs)",
                text: $weightText,
                placeholder: "—",
                onCommit: {
                    dailyLog.weight = Double(weightText)
                    onChanged()
                }
            )

            Divider()

            // Waist + hips
            metricRow(
                label: "Waist (in)",
                text: $waistText,
                placeholder: "—",
                onCommit: {
                    dailyLog.waist = Double(waistText)
                    onChanged()
                }
            )

            metricRow(
                label: "Hips (in)",
                text: $hipsText,
                placeholder: "—",
                onCommit: {
                    dailyLog.hips = Double(hipsText)
                    onChanged()
                }
            )

            // WHR auto-calc
            if let ratio = whr, let category = whrCategory {
                Divider()
                HStack {
                    Text("WHR")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(String(format: "%.2f", ratio))
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(AppTheme.ink)
                    Text("·")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(category)
                        .font(.caption)
                        .foregroundStyle(whrColor(category))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(whrColor(category).opacity(0.12))
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                }
            } else {
                SegmentEmptyState(message: "Take your measurements when ready")
            }
        }
        .onAppear { loadValues() }
    }

    private func loadValues() {
        guard !didLoadValues else { return }
        didLoadValues = true
        if let w = dailyLog.weight { weightText = formatValue(w) }
        if let w = dailyLog.waist { waistText = formatValue(w) }
        if let h = dailyLog.hips { hipsText = formatValue(h) }
    }

    @ViewBuilder
    private func metricRow(
        label: String,
        text: Binding<String>,
        placeholder: String,
        onCommit: @escaping () -> Void
    ) -> some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundStyle(AppTheme.ink)
            Spacer()
            TextField(placeholder, text: text)
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.trailing)
                .frame(width: 80)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(AppTheme.ink)
                .onSubmit(onCommit)
                .onChange(of: text.wrappedValue) { _, _ in onCommit() }
        }
    }

    private func whrColor(_ category: String) -> Color {
        switch category {
        case "Healthy": return Color(hex: "#4CAF50")
        case "Moderate": return Color(hex: "#FF9800")
        default: return Color(hex: "#F44336")
        }
    }

    private func formatValue(_ v: Double) -> String {
        v == v.rounded() ? String(Int(v)) : String(format: "%.1f", v)
    }
}

// Collapsed summary
struct BodyMetricsCollapsedSummary: View {
    let dailyLog: DailyLog

    private var whr: Double? {
        guard let waist = dailyLog.waist, let hips = dailyLog.hips, hips > 0 else {
            return nil
        }
        return waist / hips
    }

    var body: some View {
        if dailyLog.weight == nil && dailyLog.waist == nil {
            SegmentSummaryText(text: "No measurements yet")
        } else {
            HStack(spacing: 8) {
                if let weight = dailyLog.weight {
                    SegmentSummaryText(text: "\(formatValue(weight)) lbs")
                }
                if let ratio = whr {
                    SegmentSummaryText(text: "WHR: \(String(format: "%.2f", ratio))")
                }
            }
        }
    }

    private func formatValue(_ v: Double) -> String {
        v == v.rounded() ? String(Int(v)) : String(format: "%.1f", v)
    }
}
