import SwiftUI
import SwiftData
import PhotosUI
import UIKit

struct DashboardView: View {
    let profile: UserProfile

    @Environment(\.modelContext) private var modelContext
    @Query(sort: \DailyLog.date, order: .reverse) private var dailyLogs: [DailyLog]
    @Query(sort: \WHREntry.date, order: .reverse) private var whrEntries: [WHREntry]
    @Query(sort: \WeeklyMetrics.date, order: .reverse) private var weeklyMetrics: [WeeklyMetrics]

    @State private var settings = UserSettings()
    @StateObject private var healthKit = HealthKitManager.shared
    @State private var isCheckInExpanded = false
    @State private var dailyLog: DailyLog?
    @State private var saveTask: Task<Void, Never>?
    @State private var savedIndicator = false

    // Sheet state
    @State private var showWeeklyWeighIn = false
    @State private var showWHRCalculator = false
    @State private var showPhotoLog = false

    // Focus state
    enum Field: Hashable {
        case notes
        case steps
        case mealNote(UUID)
    }
    @FocusState private var focusedField: Field?
    @State private var focusedMealID: UUID?

    // Steps
    @State private var stepsText = ""
    @State private var metricsLoaded = false
    @State private var showManualStepEntry = false
    @State private var manualStepsText = ""

    private var summary: HomeViewModel {
        HomeViewModel(dailyLogs: dailyLogs, whrEntries: whrEntries, weeklyMetrics: weeklyMetrics)
    }

    private var latestWHR: WeeklyMetrics? {
        weeklyMetrics.first(where: { $0.whr > 0 })
    }

    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 6..<12:  return "Good morning"
        case 12..<18: return "Good afternoon"
        case 18..<22: return "Good evening"
        default:      return "Good night"
        }
    }

    private var greetingEmoji: String {
        let hour = Calendar.current.component(.hour, from: Date())
        return (6..<18).contains(hour) ? "☀️" : "🌙"
    }

    private var todayDateString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMMM d"
        return formatter.string(from: Date())
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: AppSpacing.sectionSpacing) {
                    greetingHeader
                    quickStatsRow
                    todayCheckInSection
                    recentInsightCard
                    quickActionsSection
                }
                .padding(.horizontal, AppSpacing.screenPadding)
                .padding(.top, AppSpacing.lg)
                .padding(.bottom, AppSpacing.xxl)
            }
            .background(Color.appBackground.ignoresSafeArea())
            .scrollDismissesKeyboard(.interactively)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    if savedIndicator {
                        HStack(spacing: 4) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(Color.appSuccess)
                            Text("Saved")
                                .font(AppFonts.footnote)
                                .foregroundStyle(Color.appTextSecondary)
                        }
                        .transition(.opacity)
                    } else {
                        Text("Nudge Notes")
                            .font(AppFonts.captionEmphasized)
                            .foregroundStyle(Color.appTextSecondary)
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    if profile.isPro {
                        Label("Pro", systemImage: "star.fill")
                            .font(AppFonts.footnote)
                            .foregroundStyle(Color.appAccent)
                            .labelStyle(.iconOnly)
                    }
                }
            }
            .sheet(isPresented: $showWeeklyWeighIn) {
                WeeklyWeighInView(date: Date())
            }
            .sheet(isPresented: $showWHRCalculator) {
                WHRCalculatorView(date: Date())
            }
            .sheet(isPresented: $showPhotoLog) {
                PhotoLoggingView(date: Date())
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
            loadOrCreateTodayLog()
            if healthKit.isAuthorized {
                Task { await healthKit.fetchTodayData() }
            }
        }
    }

    // MARK: - Greeting Header

    @ViewBuilder
    private var greetingHeader: some View {
        HStack {
            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                Text("\(greeting) \(greetingEmoji)")
                    .font(AppFonts.title)
                    .foregroundStyle(Color.appText)
                    .accessibilityAddTraits(.isHeader)

                Text(todayDateString)
                    .font(AppFonts.caption)
                    .foregroundStyle(Color.appTextSecondary)
            }
            Spacer()
        }
    }

    // MARK: - Quick Stats Row

    @ViewBuilder
    private var quickStatsRow: some View {
        HStack(spacing: AppSpacing.sm) {
            if let whr = latestWHR, whr.whr > 0 {
                statCard(
                    label: "WHR",
                    value: String(format: "%.2f", whr.whr),
                    color: whrZoneColor(whr.whr)
                )
            }

            statCard(
                label: "Streak",
                value: "\(summary.currentStreak)d",
                color: Color.appAccent
            )

            let daysLogged = daysLoggedThisMonth
            statCard(
                label: "Logged",
                value: "\(daysLogged)/\(daysInMonthSoFar)",
                color: Color.appTextSecondary
            )
        }
    }

    @ViewBuilder
    private func statCard(label: String, value: String, color: Color) -> some View {
        AppCard {
            VStack(spacing: 4) {
                Text(value)
                    .font(AppFonts.headline)
                    .foregroundStyle(color)
                Text(label)
                    .font(AppFonts.footnote)
                    .foregroundStyle(Color.appTextSecondary)
            }
            .frame(maxWidth: .infinity)
        }
    }

    // MARK: - WHR Card (prominent)

    @ViewBuilder
    private var whrProminent: some View {
        if let metrics = latestWHR, metrics.whr > 0 {
            AppCard {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Current WHR")
                            .font(AppFonts.caption)
                            .foregroundStyle(Color.appTextSecondary)
                        Text(String(format: "%.2f", metrics.whr))
                            .font(AppFonts.title)
                            .foregroundStyle(whrZoneColor(metrics.whr))
                        Text(whrZoneLabel(metrics.whr))
                            .font(AppFonts.caption)
                            .foregroundStyle(whrZoneColor(metrics.whr))
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("Last Weigh-In")
                            .font(AppFonts.caption)
                            .foregroundStyle(Color.appTextSecondary)
                        Text(metrics.date, style: .date)
                            .font(AppFonts.caption)
                            .foregroundStyle(Color.appTextSecondary)
                        if Calendar.current.dateComponents([.day], from: metrics.date, to: Date()).day ?? 0 >= 7 {
                            Button {
                                showWeeklyWeighIn = true
                            } label: {
                                Text("Update Now")
                                    .font(AppFonts.captionEmphasized)
                                    .foregroundStyle(Color.appAccent)
                            }
                        }
                    }
                }
            }
        }
    }

    // MARK: - Today's Check-In Section

    @ViewBuilder
    private var todayCheckInSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            // Header with expand/collapse
            Button {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    isCheckInExpanded.toggle()
                }
                hapticFeedback(.light)
            } label: {
                HStack {
                    Text(isCheckInExpanded ? "Today's Check-In" : "Quick Check-In")
                        .font(AppFonts.headline)
                        .foregroundStyle(Color.appText)
                    Spacer()
                    Image(systemName: "chevron.down")
                        .foregroundStyle(Color.appAccent)
                        .rotationEffect(.degrees(isCheckInExpanded ? 180 : 0))
                        .animation(.spring(response: 0.3), value: isCheckInExpanded)
                }
            }
            .buttonStyle(.plain)

            if isCheckInExpanded {
                // Full daily check-in form
                if let log = dailyLog {
                    expandedCheckIn(log: log)
                }
            } else {
                // Quick action buttons
                quickLogButtons
            }
        }
    }

    @ViewBuilder
    private var quickLogButtons: some View {
        if let log = dailyLog {
            HStack(spacing: AppSpacing.sm) {
                quickActionButton(icon: "drop.fill", label: "Water", value: "\(totalGlasses(log: log))") {
                    let entry = WaterLog(amount: 1.0, unit: .glasses, dailyLog: log)
                    log.waterLogs.append(entry)
                    scheduleAutoSave()
                    hapticFeedback(.light)
                }

                quickActionButton(
                    icon: moodIcon(log.mood),
                    label: "Mood",
                    value: log.mood != nil ? moodLabel(log.mood!) : "—"
                ) {
                    let next = ((log.mood ?? 0) % 5) + 1
                    log.mood = next
                    scheduleAutoSave()
                    hapticFeedback(.light)
                }

                quickActionButton(icon: "bed.double.fill", label: "Sleep", value: sleepDisplay(log)) {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        isCheckInExpanded = true
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func quickActionButton(icon: String, label: String, value: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            AppCard {
                VStack(spacing: 6) {
                    Image(systemName: icon)
                        .font(.title3)
                        .foregroundStyle(Color.appAccent)
                    Text(value)
                        .font(AppFonts.captionEmphasized)
                        .foregroundStyle(Color.appText)
                    Text(label)
                        .font(AppFonts.footnote)
                        .foregroundStyle(Color.appTextSecondary)
                }
                .frame(maxWidth: .infinity)
            }
        }
        .buttonStyle(.plain)
    }

    // MARK: - Expanded Check-In

    @ViewBuilder
    private func expandedCheckIn(log: DailyLog) -> some View {
        VStack(spacing: AppSpacing.md) {
            sleepSection(log: log)
            waterSection(log: log)
            movementSection(log: log)
            mealsSection(log: log)
            moodSection(log: log)
            notesSection(log: log)
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

                HStack(spacing: AppSpacing.sm) {
                    ForEach([5, 6, 7, 8, 9, 10], id: \.self) { hours in
                        Button {
                            log.sleepHours = Double(hours)
                            scheduleAutoSave()
                            hapticFeedback(.light)
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

                if log.sleepHours != nil {
                    Divider()
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

                if settings.sleepGoalEnabled, let actual = log.sleepHours {
                    let goal = settings.sleepGoalHours
                    HStack {
                        if actual >= goal {
                            Text("Goal reached!")
                                .font(AppFonts.captionEmphasized)
                                .foregroundStyle(Color.appSuccess)
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
                            hapticFeedback(.light)
                        } label: {
                            Image(systemName: index < filled ? "drop.fill" : "drop")
                                .font(.title2)
                                .foregroundStyle(index < filled ? Color.appAccent : Color.appBorder)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, AppSpacing.xs)
                        }
                        .buttonStyle(.plain)
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
                            .foregroundStyle(Color.appSuccess)
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

                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        if healthKit.isAuthorized {
                            let displaySteps = log.steps ?? healthKit.todaySteps
                            Text("\(displaySteps) steps")
                                .font(AppFonts.headline)
                                .foregroundStyle(Color.appText)
                            Text(log.steps != nil ? "Manual override" : "Auto-synced")
                                .font(AppFonts.caption)
                                .foregroundStyle(Color.appTextSecondary)
                        } else {
                            Text("Steps")
                                .font(AppFonts.body)
                                .foregroundStyle(Color.appText)
                            TextField("0", text: $stepsText)
                                .keyboardType(.numberPad)
                                .autocorrectionDisabled()
                                .textInputAutocapitalization(.never)
                                .font(AppFonts.headline)
                                .foregroundStyle(Color.appText)
                                .focused($focusedField, equals: .steps)
                                .onChange(of: stepsText) { _, val in
                                    log.steps = Int(val)
                                    scheduleAutoSave()
                                }
                        }
                    }

                    Spacer()

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
                        let workout = WorkoutLog(workoutTypeName: typeName, duration: 30, dailyLog: log)
                        log.workoutLogs.append(workout)
                    } else {
                        log.workoutLogs.removeAll { $0.workoutTypeName == typeName }
                    }
                    scheduleAutoSave()
                }
            ),
            label: label
        )
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
            HStack {
                Text(mealType.rawValue)
                    .font(AppFonts.bodyEmphasized)
                    .foregroundStyle(Color.appText)
                Spacer()
                if !isLogged {
                    Button {
                        let meal = MealLog(timestamp: Date(), mealType: mealType, dailyLog: log)
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

            if let meal = mealLog {
                VStack(alignment: .leading, spacing: AppSpacing.xs) {
                    HStack(spacing: AppSpacing.xs) {
                        ForEach(MealQuality.allCases, id: \.self) { type in
                            mealQualityButton(meal: meal, type: type)
                        }
                    }

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

                    if focusedMealID == meal.id || (meal.notes != nil && !(meal.notes?.isEmpty ?? true)) {
                        TextField("Quick note (optional)", text: Binding(
                            get: { meal.notes ?? "" },
                            set: { meal.notes = $0.isEmpty ? nil : $0 }
                        ))
                        .font(AppFonts.caption)
                        .textFieldStyle(.roundedBorder)
                        .focused($focusedField, equals: .mealNote(meal.id))
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
                            hapticFeedback(.light)
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
                .focused($focusedField, equals: .notes)
            }
        }
    }

    // MARK: - Recent Insight Card

    @ViewBuilder
    private var recentInsightCard: some View {
        let weekData = InsightsEngine.buildWeekData(logs: dailyLogs, settings: settings)
        if let insight = weekData.topInsight {
            AppCard {
                HStack(alignment: .top, spacing: AppSpacing.sm) {
                    Text("💡")
                        .font(.system(size: 20))
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Weekly Insight")
                            .font(AppFonts.captionEmphasized)
                            .foregroundStyle(Color.appText)
                        Text(insight)
                            .font(AppFonts.caption)
                            .foregroundStyle(Color.appTextSecondary)
                    }
                    Spacer()
                }
            }
        }
    }

    // MARK: - Quick Actions

    @ViewBuilder
    private var quickActionsSection: some View {
        VStack(spacing: AppSpacing.sm) {
            HStack(spacing: AppSpacing.sm) {
                AppButton("Weekly Weigh-In", variant: .secondary) {
                    showWeeklyWeighIn = true
                }
                AppButton("Photos", variant: .secondary) {
                    showPhotoLog = true
                }
            }
            HStack(spacing: AppSpacing.sm) {
                AppButton("WHR Calculator", variant: .secondary) {
                    showWHRCalculator = true
                }
                Spacer()
            }
        }
    }

    // MARK: - Helpers

    private func totalGlasses(log: DailyLog) -> Int {
        Int(log.waterLogs.reduce(0.0) { $0 + settings.waterUnit.toGlasses($1.amount) })
    }

    private func fastingWindowText(log: DailyLog) -> String? {
        let sorted = log.meals.sorted { $0.timestamp < $1.timestamp }
        guard sorted.count >= 2, let first = sorted.first, let last = sorted.last else { return nil }
        let eatingWindow = last.timestamp.timeIntervalSince(first.timestamp)
        guard eatingWindow > 0 else { return nil }
        let fasting = max(0, 24 * 3600 - eatingWindow)
        let fHours = Int(fasting / 3600)
        let fMinutes = Int(fasting.truncatingRemainder(dividingBy: 3600) / 60)
        return "Fasting: \(fHours)h \(fMinutes)m"
    }

    private func sleepDisplay(_ log: DailyLog) -> String {
        if let hours = log.sleepHours { return "\(Int(hours))h" }
        return "—"
    }

    private func moodIcon(_ mood: Int?) -> String {
        mood != nil ? "face.smiling.fill" : "face.smiling"
    }

    private func moodLabel(_ mood: Int) -> String {
        ["", "Very Low", "Low", "OK", "Good", "Great"][min(mood, 5)]
    }

    private func whrZoneColor(_ whr: Double) -> Color {
        if whr < 0.80 { return Color.appSuccess }
        if whr < 0.85 { return Color.appWarning }
        return Color.appDanger
    }

    private func whrZoneLabel(_ whr: Double) -> String {
        if whr < 0.80 { return "Healthy" }
        if whr < 0.85 { return "Elevated" }
        return "High Risk"
    }

    private var daysLoggedThisMonth: Int {
        let cal = Calendar.current
        let now = Date()
        guard let monthStart = cal.date(from: cal.dateComponents([.year, .month], from: now)) else { return 0 }
        let thisMonthLogs = dailyLogs.filter { $0.date >= monthStart && $0.date <= now }
        return Set(thisMonthLogs.map { cal.startOfDay(for: $0.date) }).count
    }

    private var daysInMonthSoFar: Int {
        Calendar.current.component(.day, from: Date())
    }

    // MARK: - Data

    private func loadOrCreateTodayLog() {
        let start = Calendar.current.startOfDay(for: Date())
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
            let log = DailyLog(date: Date())
            modelContext.insert(log)
            try? modelContext.save()
            dailyLog = log
        }
    }

    private func loadTextFields(from log: DailyLog) {
        guard !metricsLoaded else { return }
        metricsLoaded = true
        if let s = log.steps { stepsText = "\(s)" }
    }

    // MARK: - Auto-Save (debounced 0.3s)

    private func scheduleAutoSave() {
        saveTask?.cancel()
        saveTask = Task {
            try? await Task.sleep(nanoseconds: 300_000_000)
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

    // MARK: - Haptic Feedback

    private func hapticFeedback(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.impactOccurred()
    }
}
