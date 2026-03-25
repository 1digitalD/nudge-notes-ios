import SwiftUI
import SwiftData

struct HydrationSegmentView: View {
    @Bindable var dailyLog: DailyLog
    var settings: UserSettings
    var onChanged: () -> Void

    @State private var isEditingGoal = false
    @State private var goalText = ""
    @State private var waterToDelete: WaterLog?

    private var sortedLogs: [WaterLog] {
        dailyLog.waterLogs.sorted { $0.timestamp < $1.timestamp }
    }

    private var totalGlasses: Double {
        dailyLog.waterLogs.reduce(0) { $0 + settings.waterUnit.toGlasses($1.amount) }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Progress bar + label
            VStack(alignment: .leading, spacing: 4) {
                ProgressBar(current: totalGlasses, goal: Double(settings.waterGoalGlasses))
                ProgressLabel(
                    current: totalGlasses,
                    goal: Double(settings.waterGoalGlasses),
                    unit: "glasses"
                )
            }

            // Quick-add preset
            IncrementalInput(
                label: "Water intake",
                currentValue: totalGlasses,
                goal: Double(settings.waterGoalGlasses),
                unit: "glasses",
                presetLabel: "+\(formatPreset(settings.waterQuickPreset)) \(settings.waterUnit.label)",
                onIncrement: addWaterPreset
            )

            // Logged entries
            if sortedLogs.isEmpty {
                SegmentEmptyState(message: "Tap + to log your first glass")
            } else {
                VStack(spacing: 0) {
                    ForEach(sortedLogs) { log in
                        HStack {
                            Text(log.timestamp, style: .time)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .frame(width: 60, alignment: .leading)
                            Text("\(formatAmount(log.amount)) \(log.unit.label)")
                                .font(.subheadline)
                                .foregroundStyle(Color.appText)
                            Spacer()
                            Button {
                                withAnimation {
                                    dailyLog.waterLogs.removeAll { $0.id == log.id }
                                    onChanged()
                                }
                            } label: {
                                Image(systemName: "minus.circle")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            .accessibilityLabel("Remove water entry")
                        }
                        .padding(.vertical, 4)

                        if log.id != sortedLogs.last?.id {
                            Divider()
                        }
                    }
                }
                .padding(.vertical, 4)
                .padding(.horizontal, 8)
                .background(Color.appCard.opacity(0.5))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }

            // Unit + goal settings row
            HStack(spacing: 8) {
                Picker("Unit", selection: Binding(
                    get: { settings.waterUnit },
                    set: { settings.waterUnit = $0; onChanged() }
                )) {
                    ForEach(WaterUnit.allCases, id: \.self) { unit in
                        Text(unit.label).tag(unit)
                    }
                }
                .pickerStyle(.segmented)
                .frame(maxWidth: 180)

                Spacer()

                Text("Goal:")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                if isEditingGoal {
                    TextField("", text: $goalText)
                        .keyboardType(.numberPad)
                        .frame(width: 40)
                        .multilineTextAlignment(.center)
                        .font(.caption.weight(.semibold))
                        .onSubmit { commitGoal() }
                        .onAppear { goalText = "\(settings.waterGoalGlasses)" }
                } else {
                    Button {
                        goalText = "\(settings.waterGoalGlasses)"
                        isEditingGoal = true
                    } label: {
                        Text("\(settings.waterGoalGlasses) glasses")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(Color.appAccent)
                    }
                }
            }
            .padding(.top, 4)
        }
    }

    private func addWaterPreset() {
        let log = WaterLog(
            timestamp: Date(),
            amount: settings.waterQuickPreset,
            unit: settings.waterUnit,
            dailyLog: dailyLog
        )
        dailyLog.waterLogs.append(log)
        onChanged()
    }

    private func commitGoal() {
        if let value = Int(goalText), value > 0 {
            settings.waterGoalGlasses = value
        }
        isEditingGoal = false
        onChanged()
    }

    private func formatAmount(_ v: Double) -> String {
        v == v.rounded() ? String(Int(v)) : String(format: "%.1f", v)
    }

    private func formatPreset(_ v: Double) -> String {
        v == v.rounded() ? String(Int(v)) : String(format: "%.1f", v)
    }
}

// Collapsed summary
struct HydrationCollapsedSummary: View {
    let dailyLog: DailyLog
    let settings: UserSettings

    private var totalGlasses: Double {
        dailyLog.waterLogs.reduce(0) { $0 + settings.waterUnit.toGlasses($1.amount) }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            ProgressBar(current: totalGlasses, goal: Double(settings.waterGoalGlasses))
            SegmentSummaryText(text: "\(formatValue(totalGlasses))/\(settings.waterGoalGlasses) glasses")
        }
    }

    private func formatValue(_ v: Double) -> String {
        v == v.rounded() ? String(Int(v)) : String(format: "%.1f", v)
    }
}
