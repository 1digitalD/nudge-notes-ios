import SwiftUI

/// A quick-add row: shows current/goal and a preset increment button
struct IncrementalInput: View {
    let label: String
    let currentValue: Double
    let goal: Double
    let unit: String
    let presetLabel: String
    let onIncrement: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.ink)
                ProgressLabel(current: currentValue, goal: goal, unit: unit)
            }

            Spacer()

            Button(action: onIncrement) {
                HStack(spacing: 4) {
                    Image(systemName: "plus")
                        .font(.caption.weight(.bold))
                    Text(presetLabel)
                        .font(.caption.weight(.semibold))
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(AppTheme.accent.opacity(0.12))
                .foregroundStyle(AppTheme.accent)
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            .accessibilityLabel("Add \(presetLabel) \(unit)")
        }
    }
}
