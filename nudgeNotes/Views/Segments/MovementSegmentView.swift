import SwiftUI

struct MovementSegmentView: View {
    @Bindable var dailyLog: DailyLog
    var settings: UserSettings
    var onChanged: () -> Void

    @State private var showAddWorkout = false
    @State private var editingSteps = false
    @State private var stepsText = ""

    private var sortedWorkouts: [WorkoutLog] {
        dailyLog.workoutLogs.sorted { $0.timestamp < $1.timestamp }
    }

    private var steps: Int { dailyLog.steps ?? 0 }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Steps progress
            VStack(alignment: .leading, spacing: 4) {
                ProgressBar(current: Double(steps), goal: Double(settings.stepGoal))
                ProgressLabel(current: Double(steps), goal: Double(settings.stepGoal), unit: "steps")
            }

            // Steps quick-add row
            HStack(spacing: 12) {
                if editingSteps {
                    HStack {
                        TextField("Steps", text: $stepsText)
                            .keyboardType(.numberPad)
                            .font(.subheadline)
                            .onSubmit { commitSteps() }
                        Button("Done") { commitSteps() }
                            .font(.subheadline)
                            .foregroundStyle(AppTheme.accent)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 8)
                    .background(AppTheme.paper.opacity(0.5))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                } else {
                    Button {
                        stepsText = steps > 0 ? "\(steps)" : ""
                        editingSteps = true
                    } label: {
                        HStack {
                            Text("Steps: \(steps)")
                                .font(.subheadline)
                                .foregroundStyle(AppTheme.ink)
                            Image(systemName: "pencil")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .buttonStyle(.plain)
                }

                Spacer()

                Button {
                    dailyLog.steps = (dailyLog.steps ?? 0) + settings.stepQuickPreset
                    onChanged()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "plus")
                            .font(.caption.weight(.bold))
                        Text("+\(settings.stepQuickPreset)")
                            .font(.caption.weight(.semibold))
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(AppTheme.accent.opacity(0.12))
                    .foregroundStyle(AppTheme.accent)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                .accessibilityLabel("Add \(settings.stepQuickPreset) steps")
            }

            // Workouts list
            if sortedWorkouts.isEmpty {
                SegmentEmptyState(message: "Log steps or add a workout")
            } else {
                VStack(spacing: 0) {
                    ForEach(sortedWorkouts) { workout in
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(workout.workoutTypeName)
                                    .font(.subheadline)
                                    .foregroundStyle(AppTheme.ink)
                                HStack(spacing: 4) {
                                    Text("\(workout.duration) min")
                                    Text("·")
                                    Text(workout.intensity.rawValue)
                                }
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Text(workout.timestamp, style: .time)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Button {
                                withAnimation {
                                    dailyLog.workoutLogs.removeAll { $0.id == workout.id }
                                    onChanged()
                                }
                            } label: {
                                Image(systemName: "minus.circle")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            .padding(.leading, 8)
                            .accessibilityLabel("Remove workout")
                        }
                        .padding(.vertical, 6)

                        if workout.id != sortedWorkouts.last?.id {
                            Divider()
                        }
                    }
                }
                .padding(.vertical, 4)
                .padding(.horizontal, 8)
                .background(AppTheme.paper.opacity(0.5))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }

            // Add workout button
            Button {
                showAddWorkout = true
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "plus")
                        .font(.caption.weight(.bold))
                    Text("Add Workout")
                        .font(.caption.weight(.semibold))
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(AppTheme.accent.opacity(0.12))
                .foregroundStyle(AppTheme.accent)
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            .accessibilityIdentifier("add-workout-button")
        }
        .sheet(isPresented: $showAddWorkout) {
            AddWorkoutSheet(settings: settings) { workout in
                workout.dailyLog = dailyLog
                dailyLog.workoutLogs.append(workout)
                onChanged()
            }
        }
    }

    private func commitSteps() {
        if let value = Int(stepsText) {
            dailyLog.steps = value
            onChanged()
        }
        editingSteps = false
    }
}

// MARK: - Add Workout Sheet

struct AddWorkoutSheet: View {
    @Environment(\.dismiss) private var dismiss
    var settings: UserSettings
    var onAdd: (WorkoutLog) -> Void

    @State private var selectedType = PredefinedWorkoutType.walking.rawValue
    @State private var duration = 30
    @State private var intensity = IntensityLevel.moderate
    @State private var notes = ""
    @State private var isCustomType = false
    @State private var customTypeName = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("Workout Type") {
                    Picker("Type", selection: $selectedType) {
                        ForEach(settings.allWorkoutTypes, id: \.self) { type in
                            Text(type).tag(type)
                        }
                        Text("Custom…").tag("__custom__")
                    }
                    .onChange(of: selectedType) { _, new in
                        isCustomType = new == "__custom__"
                    }

                    if isCustomType {
                        TextField("Custom workout name", text: $customTypeName)
                    }
                }

                Section("Duration & Intensity") {
                    Stepper("\(duration) minutes", value: $duration, in: 5...300, step: 5)
                    Picker("Intensity", selection: $intensity) {
                        ForEach(IntensityLevel.allCases, id: \.self) { level in
                            Text(level.rawValue).tag(level)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                Section("Notes") {
                    TextField("Optional notes", text: $notes, axis: .vertical)
                        .lineLimit(2...4)
                }
            }
            .navigationTitle("Add Workout")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Add") {
                        let typeName = isCustomType ? customTypeName : selectedType
                        guard !typeName.isEmpty else { return }

                        if isCustomType && !customTypeName.isEmpty &&
                           !settings.customWorkoutTypes.contains(customTypeName) {
                            settings.customWorkoutTypes.append(customTypeName)
                        }

                        let workout = WorkoutLog(
                            workoutTypeName: typeName,
                            duration: duration,
                            intensity: intensity,
                            notes: notes.isEmpty ? nil : notes
                        )
                        onAdd(workout)
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .foregroundStyle(AppTheme.accent)
                    .accessibilityIdentifier("confirm-add-workout-button")
                }
            }
        }
    }
}

// Collapsed summary
struct MovementCollapsedSummary: View {
    let dailyLog: DailyLog
    let settings: UserSettings

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            ProgressBar(
                current: Double(dailyLog.steps ?? 0),
                goal: Double(settings.stepGoal)
            )
            HStack(spacing: 6) {
                SegmentSummaryText(text: "\(dailyLog.steps ?? 0)/\(settings.stepGoal) steps")
                if !dailyLog.workoutLogs.isEmpty {
                    Text("·")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    SegmentSummaryText(text: "\(dailyLog.workoutLogs.count) workout\(dailyLog.workoutLogs.count == 1 ? "" : "s")")
                }
            }
        }
    }
}
