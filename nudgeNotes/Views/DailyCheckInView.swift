import SwiftUI
import SwiftData
import PhotosUI

struct DailyCheckInView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    let date: Date
    let existingLog: DailyLog?

    @State private var settings = UserSettings()
    @StateObject private var healthKit = HealthKitManager.shared
    @State private var saveTask: Task<Void, Never>?
    @State private var savedIndicator = false
    @State private var dailyLog: DailyLog?

    // Text state for numeric fields (loaded once from model)
    @State private var stepsText = ""
    @State private var metricsLoaded = false
    @State private var showManualStepEntry = false
    @State private var manualStepsText = ""

    // Meal note focus
    @State private var focusedMealID: UUID?

    init(date: Date, existingLog: DailyLog? = nil) {
        self.date = date
        self.existingLog = existingLog
    }

    var body: some View {
        NavigationStack {
            Group {
                if let log = dailyLog {
                    ScrollView {
                        VStack(spacing: AppSpacing.md) {
                            sleepSection(log: log)
                            waterSection(log: log)
                            movementSection(log: log)
                            mealsSection(log: log)
                            moodSection(log: log)
                            notesSection(log: log)
                        }
                        .padding(.horizontal, AppSpacing.md)
                        .padding(.top, AppSpacing.sm)
                        .padding(.bottom, AppSpacing.xl)
                    }
                    .background(Color.appBackground)
                } else {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .navigationTitle(navigationTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close") { dismiss() }
                        .foregroundStyle(.secondary)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    if savedIndicator {
                        HStack(spacing: 4) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(Color(hex: "#4CAF50"))
                            Text("Saved")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .transition(.opacity)
                    }
                }
            }
            .alert("Manual Steps", isPresented: $showManualStepEntry) {
                TextField("Steps", text: $manualStepsText)
                    .keyboardType(.numberPad)
                Button("Save") {
                    if let steps = Int(manualStepsText), let log = dailyLog {
                        log.steps = steps
                        scheduleAutoSave()
                    }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Override the auto-synced step count")
            }
        }
        .onAppear {
            loadOrCreateLog()
            if healthKit.isAuthorized {
                Task { await healthKit.fetchTodayData() }
            }
        }
    }

    // MARK: - Sleep Section

    @ViewBuilder
    private func sleepSection(log: DailyLog) -> some View {
        AppCard {
            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                Text("Sleep Last Night")
                    .font(AppFonts.headline)
                    .foregroundStyle(Color.appText)

                // Quick hour picker
                HStack(spacing: AppSpacing.sm) {
                    ForEach([5, 6, 7, 8, 9, 10], id: \.self) { hours in
                        Button {
                            log.sleepHours = Double(hours)
                            scheduleAutoSave()
                        } label: {
                            Text("\(hours)h")
                                .font(AppFonts.body)
                                .foregroundStyle(log.sleepHours == Double(hours) ? Color.white : Color.appText)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, AppSpacing.sm)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(log.sleepHours == Double(hours) ? Color.appAccent : Color.appCard)
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color.appBorder, lineWidth: 1)
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }

                // Optional quality (5 stars)
                if log.sleepHours != nil {
                    Divider()
                        .foregroundStyle(Color.appBorder)

                    HStack {
                        Text("Quality (optional)")
                            .font(AppFonts.caption)
                            .foregroundStyle(Color.appTextSecondary)

                        Spacer()

                        ForEach(1...5, id: \.self) { star in
                            Button {
                                log.sleepQuality = (log.sleepQuality == star) ? nil : star
                                scheduleAutoSave()
                            } label: {
                                Image(systemName: (log.sleepQuality ?? 0) >= star ? "star.fill" : "star")
                                    .foregroundStyle(Color.appAccent)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }

                // Show goal if set
                if settings.sleepGoalEnabled, let actual = log.sleepHours {
                    let goal = settings.sleepGoalHours
                    HStack {
                        if actual >= goal {
                            Text("Goal reached!")
                                .font(AppFonts.captionEmphasized)
                                .foregroundStyle(Color.appAccent)
                        } else {
                            Text("\(Int(goal - actual))h short of \(Int(goal))h goal")
                                .font(AppFonts.caption)
                                .foregroundStyle(Color.appTextSecondary)
                        }
                        Spacer()
                    }
                }
            }
        }
    }

    // MARK: - Water Section

    @ViewBuilder
    private func waterSection(log: DailyLog) -> some View {
        AppCard {
            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                Text("Hydration")
                    .font(AppFonts.headline)
                    .foregroundStyle(Color.appText)

                let filled = totalGlasses(log: log)
                let goal = settings.waterGoalGlasses

                HStack(spacing: 0) {
                    ForEach(0..<8, id: \.self) { index in
                        Button {
                            let sorted = log.waterLogs.sorted { $0.timestamp < $1.timestamp }
                            if index < filled {
                                if let last = sorted.last {
                                    log.waterLogs.removeAll { $0.id == last.id }
                                }
                            } else {
                                let entry = WaterLog(amount: 1.0, unit: .glasses, dailyLog: log)
                                log.waterLogs.append(entry)
                            }
                            scheduleAutoSave()
                        } label: {
                            Image(systemName: index < filled ? "drop.fill" : "drop")
                                .font(.title2)
                                .foregroundStyle(index < filled ? Color.appAccent : Color.appBorder)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, AppSpacing.xs)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel(index < filled ? "Remove one glass" : "Add one glass")
                    }
                }

                HStack {
                    Text("\(filled) of \(goal) glasses")
                        .font(AppFonts.caption)
                        .foregroundStyle(Color.appTextSecondary)
                    Spacer()
                    if settings.waterGoalEnabled && filled >= goal {
                        Text("Goal reached!")
                            .font(AppFonts.captionEmphasized)
                            .foregroundStyle(Color.appAccent)
                    }
                }
            }
        }
    }

    // MARK: - Movement Section

    @ViewBuilder
    private func movementSection(log: DailyLog) -> some View {
        AppCard {
            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                Text("Movement")
                    .font(AppFonts.headline)
                    .foregroundStyle(Color.appText)

                // Steps (HealthKit or manual)
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        if healthKit.isAuthorized {
                            let displaySteps = log.steps ?? healthKit.todaySteps
                            Text("\(displaySteps) steps")
                                .font(AppFonts.headline)
                                .foregroundStyle(Color.appText)
                            Text(log.steps != nil ? "Manual override" : "Auto-synced from Health")
                                .font(AppFonts.caption)
                                .foregroundStyle(Color.appTextSecondary)
                        } else {
                            Text("Steps")
                                .font(AppFonts.body)
                                .foregroundStyle(Color.appText)
                            TextField("0", text: $stepsText)
                                .keyboardType(.numberPad)
                                .multilineTextAlignment(.leading)
                                .font(AppFonts.headline)
                                .foregroundStyle(Color.appText)
                                .onChange(of: stepsText) { _, val in
                                    log.steps = Int(val)
                                    scheduleAutoSave()
                                }
                                .accessibilityLabel("Steps count")
                        }
                    }

                    Spacer()

                    // Goal progress
                    if settings.stepGoalEnabled {
                        let steps = healthKit.isAuthorized
                            ? (log.steps ?? healthKit.todaySteps)
                            : (log.steps ?? 0)
                        let progress = min(Double(steps) / Double(settings.stepGoal), 1.0)

                        VStack(alignment: .trailing, spacing: 4) {
                            Text("\(Int(progress * 100))%")
                                .font(AppFonts.captionEmphasized)
                                .foregroundStyle(Color.appAccent)

                            ProgressView(value: progress)
                                .tint(Color.appAccent)
                                .frame(width: 80)
                        }
                    }

                    // Manual override button
                    if healthKit.isAuthorized {
                        Button {
                            manualStepsText = log.steps.map { "\($0)" } ?? ""
                            showManualStepEntry = true
                        } label: {
                            Image(systemName: "pencil.circle")
                                .foregroundStyle(Color.appTextSecondary)
                        }
                    }
                }

                Divider()
                    .foregroundStyle(Color.appBorder)

                // Activity checkboxes
                HStack(spacing: AppSpacing.lg) {
                    movementCheckbox(log: log, typeName: "Walking", label: "Walked")
                    movementCheckbox(log: log, typeName: "Weights", label: "Gym")
                    movementCheckbox(log: log, typeName: "Yoga", label: "Yoga")
                    Spacer()
                }
            }
        }
    }

    @ViewBuilder
    private func movementCheckbox(log: DailyLog, typeName: String, label: String) -> some View {
        AppCheckbox(
            isChecked: Binding(
                get: { log.workoutLogs.contains { $0.workoutTypeName == typeName } },
                set: { checked in
                    if checked {
                        let workout = WorkoutLog(
                            workoutTypeName: typeName,
                            duration: 30,
                            dailyLog: log
                        )
                        log.workoutLogs.append(workout)
                    } else {
                        log.workoutLogs.removeAll { $0.workoutTypeName == typeName }
                    }
                    scheduleAutoSave()
                }
            ),
            label: label
        )
        .accessibilityHint(label)
    }

    // MARK: - Meals Section

    @ViewBuilder
    private func mealsSection(log: DailyLog) -> some View {
        AppCard {
            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    Text("Meals")
                        .font(AppFonts.headline)
                        .foregroundStyle(Color.appText)
                    Spacer()
                    if let fasting = fastingWindowText(log: log) {
                        Text(fasting)
                            .font(AppFonts.footnote)
                            .foregroundStyle(Color.appTextSecondary)
                    }
                }
                .padding(.bottom, AppSpacing.sm)

                ForEach(MealType.allCases, id: \.self) { mealType in
                    mealRow(log: log, mealType: mealType)
                    if mealType != MealType.allCases.last {
                        Divider()
                            .foregroundStyle(Color.appBorder)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func mealRow(log: DailyLog, mealType: MealType) -> some View {
        let mealLog = log.meals.first { $0.mealType == mealType }
        let isLogged = mealLog != nil

        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            // Header row
            HStack {
                Text(mealType.rawValue)
                    .font(AppFonts.bodyEmphasized)
                    .foregroundStyle(Color.appText)

                Spacer()

                if !isLogged {
                    Button {
                        let meal = MealLog(
                            timestamp: Date(),
                            mealType: mealType,
                            dailyLog: log
                        )
                        log.meals.append(meal)
                        scheduleAutoSave()
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "plus.circle.fill")
                            Text("Log")
                        }
                        .font(AppFonts.caption)
                        .foregroundStyle(Color.appAccent)
                    }
                    .buttonStyle(.plain)
                } else {
                    Button {
                        log.meals.removeAll { $0.mealType == mealType }
                        scheduleAutoSave()
                    } label: {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(Color.appAccent)
                    }
                    .buttonStyle(.plain)
                }
            }

            // Expanded details when logged
            if let meal = mealLog {
                VStack(alignment: .leading, spacing: AppSpacing.xs) {
                    // Meal quality selector
                    HStack(spacing: AppSpacing.xs) {
                        ForEach(MealQuality.allCases, id: \.self) { type in
                            mealQualityButton(meal: meal, type: type)
                        }
                    }

                    // Photo + note
                    HStack(spacing: AppSpacing.sm) {
                        MealPhotoButton(meal: meal, onChanged: scheduleAutoSave)

                        if meal.notes == nil || meal.notes?.isEmpty == true {
                            Button {
                                focusedMealID = meal.id
                            } label: {
                                HStack(spacing: 4) {
                                    Image(systemName: "text.bubble")
                                    Text("Add note")
                                }
                                .font(AppFonts.caption)
                                .foregroundStyle(Color.appTextSecondary)
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    // Note text field
                    if focusedMealID == meal.id || (meal.notes != nil && !(meal.notes?.isEmpty ?? true)) {
                        TextField("Quick note (optional)", text: Binding(
                            get: { meal.notes ?? "" },
                            set: { meal.notes = $0.isEmpty ? nil : $0 }
                        ))
                        .font(AppFonts.caption)
                        .textFieldStyle(.roundedBorder)
                        .onChange(of: meal.notes) { _, _ in scheduleAutoSave() }
                    }
                }
                .padding(.top, AppSpacing.xs)
            }
        }
        .padding(.vertical, AppSpacing.sm)
    }

    @ViewBuilder
    private func mealQualityButton(meal: MealLog, type: MealQuality) -> some View {
        Button {
            meal.quality = (meal.quality == type) ? nil : type
            scheduleAutoSave()
        } label: {
            HStack(spacing: 4) {
                Text(type.icon)
                Text(type.shortLabel)
                    .font(AppFonts.caption)
            }
            .foregroundStyle(meal.quality == type ? Color.white : Color.appText)
            .padding(.horizontal, AppSpacing.sm)
            .padding(.vertical, AppSpacing.xs)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(meal.quality == type ? Color.appAccent : Color.appCard)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(Color.appBorder, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Mood Section

    @ViewBuilder
    private func moodSection(log: DailyLog) -> some View {
        AppCard {
            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                Text("Mood")
                    .font(AppFonts.headline)
                    .foregroundStyle(Color.appText)

                let emojis = ["😢", "😐", "🙂", "😊", "😄"]
                let labels = ["Very Low", "Low", "Neutral", "Good", "Great"]

                HStack(spacing: AppSpacing.xs) {
                    ForEach(1...5, id: \.self) { value in
                        Button {
                            log.mood = (log.mood == value) ? nil : value
                            scheduleAutoSave()
                        } label: {
                            VStack(spacing: AppSpacing.xs) {
                                Text(emojis[value - 1])
                                    .font(.title2)
                                    .opacity(log.mood == nil || log.mood == value ? 1.0 : 0.35)
                                Text(labels[value - 1])
                                    .font(.system(size: 10))
                                    .foregroundStyle(log.mood == value ? Color.appAccent : Color.appTextSecondary)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, AppSpacing.sm)
                            .background(
                                RoundedRectangle(cornerRadius: 8, style: .continuous)
                                    .fill(log.mood == value ? Color.appAccent.opacity(0.12) : Color.clear)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 8, style: .continuous)
                                    .stroke(log.mood == value ? Color.appAccent : Color.clear, lineWidth: 1.5)
                            )
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel(labels[value - 1])
                    }
                }
            }
        }
    }

    // MARK: - Notes Section

    @ViewBuilder
    private func notesSection(log: DailyLog) -> some View {
        AppCard {
            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                Text("Notes")
                    .font(AppFonts.headline)
                    .foregroundStyle(Color.appText)

                TextField(
                    "Any notes for today…",
                    text: Binding(
                        get: { log.notes ?? "" },
                        set: { log.notes = $0.isEmpty ? nil : $0; scheduleAutoSave() }
                    ),
                    axis: .vertical
                )
                .lineLimit(3...8)
                .font(AppFonts.body)
                .foregroundStyle(Color.appText)
                .accessibilityIdentifier("notes-field")
            }
        }
    }

    // MARK: - Helpers

    private func totalGlasses(log: DailyLog) -> Int {
        Int(log.waterLogs.reduce(0.0) { $0 + settings.waterUnit.toGlasses($1.amount) })
    }

    private func fastingWindowText(log: DailyLog) -> String? {
        let sorted = log.meals.sorted { $0.timestamp < $1.timestamp }
        guard sorted.count >= 2,
              let first = sorted.first,
              let last = sorted.last else { return nil }
        let eatingWindow = last.timestamp.timeIntervalSince(first.timestamp)
        guard eatingWindow > 0 else { return nil }
        let fasting = max(0, 24 * 3600 - eatingWindow)
        let fHours = Int(fasting / 3600)
        let fMinutes = Int(fasting.truncatingRemainder(dividingBy: 3600) / 60)
        return "Fasting: \(fHours)h \(fMinutes)m (auto)"
    }

    private var navigationTitle: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE, MMM d"
        return formatter.string(from: date)
    }

    // MARK: - Data

    private func loadOrCreateLog() {
        if let existing = existingLog {
            dailyLog = existing
            loadTextFields(from: existing)
        } else {
            let start = Calendar.current.startOfDay(for: date)
            let end = Calendar.current.date(byAdding: .day, value: 1, to: start) ?? start
            let descriptor = FetchDescriptor<DailyLog>(
                predicate: #Predicate<DailyLog> { log in
                    log.date >= start && log.date < end
                }
            )
            if let found = try? modelContext.fetch(descriptor).first {
                dailyLog = found
                loadTextFields(from: found)
            } else {
                let log = DailyLog(date: date)
                modelContext.insert(log)
                try? modelContext.save()
                dailyLog = log
            }
        }
    }

    private func loadTextFields(from log: DailyLog) {
        guard !metricsLoaded else { return }
        metricsLoaded = true
        if let s = log.steps { stepsText = "\(s)" }
    }

    // MARK: - Auto-Save (debounced 1s)

    private func scheduleAutoSave() {
        saveTask?.cancel()
        saveTask = Task {
            try? await Task.sleep(nanoseconds: 1_000_000_000)
            guard !Task.isCancelled else { return }
            await persistSave()
        }
    }

    @MainActor
    private func persistSave() {
        guard let log = dailyLog else { return }
        log.updatedAt = Date()
        try? modelContext.save()
        withAnimation {
            savedIndicator = true
        }
        Task {
            try? await Task.sleep(nanoseconds: 2_000_000_000)
            withAnimation { savedIndicator = false }
        }
    }
}

// MARK: - Meal Photo Button

private struct MealPhotoButton: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var meal: MealLog
    let onChanged: () -> Void

    @State private var selectedItem: PhotosPickerItem?
    @State private var showDeleteConfirm = false

    private var photo: PhotoLog? { meal.photos.first }

    var body: some View {
        if let photo, let data = photo.imageData, let uiImage = UIImage(data: data) {
            Button {
                showDeleteConfirm = true
            } label: {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 40, height: 40)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(Color.appBorder, lineWidth: 1)
                    )
            }
            .buttonStyle(.plain)
            .confirmationDialog("Remove photo?", isPresented: $showDeleteConfirm) {
                Button("Remove Photo", role: .destructive) {
                    meal.photos.removeAll { $0.id == photo.id }
                    onChanged()
                }
            }
            .accessibilityLabel("Meal photo. Tap to remove.")
        } else {
            PhotosPicker(selection: $selectedItem, matching: .images) {
                HStack(spacing: 4) {
                    Image(systemName: "camera")
                        .font(AppFonts.footnote)
                    Text("Add Photo")
                        .font(AppFonts.footnote)
                }
                .foregroundStyle(Color.appAccent)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.appAccent.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 6))
            }
            .onChange(of: selectedItem) { _, item in
                guard let item else { return }
                Task {
                    if let data = try? await item.loadTransferable(type: Data.self) {
                        let photoLog = PhotoLog(date: Date(), category: .meal, imageData: data)
                        modelContext.insert(photoLog)
                        meal.photos.append(photoLog)
                        onChanged()
                    }
                    selectedItem = nil
                }
            }
            .accessibilityLabel("Add meal photo")
        }
    }
}
