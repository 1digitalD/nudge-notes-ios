import SwiftUI
import SwiftData

struct SettingsView: View {
    let profile: UserProfile

    @Environment(\.modelContext) private var modelContext
    @Query(sort: \DailyLog.date, order: .reverse) private var dailyLogs: [DailyLog]

    @State private var settings = UserSettings()
    @State private var subscriptionStore: SubscriptionStore
    @State private var isPresentingUpgrade = false
    @State private var isPresentingDeleteConfirm = false

    // Profile fields (backed by UserDefaults)
    @State private var nameText: String = UserDefaults.standard.string(forKey: "userName") ?? ""
    @State private var heightText: String = UserDefaults.standard.string(forKey: "userHeight") ?? ""

    // Goals as text (initialized from settings)
    @State private var waterGoalText = ""
    @State private var stepGoalText = ""

    init(profile: UserProfile) {
        self.profile = profile
        _subscriptionStore = State(initialValue: SubscriptionStore(profile: profile))
    }

    private var exportViewModel: HistoryViewModel {
        HistoryViewModel(dailyLogs: dailyLogs, profileIsPro: profile.isPro)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: AppSpacing.sectionSpacing) {
                    profileSection
                    preferencesSection
                    goalsSection
                    dataPrivacySection
                    supportSection
                }
                .padding(.horizontal, AppSpacing.md)
                .padding(.top, AppSpacing.sm)
                .padding(.bottom, AppSpacing.xl)
            }
            .background(Color.appBackground)
            .navigationTitle("Settings")
            .sheet(isPresented: $isPresentingUpgrade) {
                ProUpgradeView(profile: profile)
            }
            .alert("Delete All Data", isPresented: $isPresentingDeleteConfirm) {
                Button("Delete", role: .destructive) { deleteAllData() }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This will permanently delete all your logs and cannot be undone.")
            }
            .task {
                waterGoalText = "\(settings.waterGoalGlasses)"
                stepGoalText = "\(settings.stepGoal)"
                await subscriptionStore.loadProducts(modelContext: modelContext)
            }
        }
    }

    // MARK: - Section 1: Profile
    private var profileSection: some View {
        AppCard {
            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                Text("Profile")
                    .font(AppFonts.headline)
                    .foregroundColor(.appText)

                Divider()

                VStack(alignment: .leading, spacing: AppSpacing.xs) {
                    Text("Name")
                        .font(AppFonts.footnote)
                        .foregroundColor(.appTextSecondary)
                    AppTextField(placeholder: "Your name", text: $nameText)
                        .onChange(of: nameText) { _, val in
                            UserDefaults.standard.set(val, forKey: "userName")
                        }
                }

                VStack(alignment: .leading, spacing: AppSpacing.xs) {
                    Text("Height")
                        .font(AppFonts.footnote)
                        .foregroundColor(.appTextSecondary)
                    AppTextField(placeholder: "e.g. 5'7\" or 170 cm", text: $heightText)
                        .onChange(of: heightText) { _, val in
                            UserDefaults.standard.set(val, forKey: "userHeight")
                        }
                }

                HStack {
                    Text("Plan")
                        .font(AppFonts.body)
                        .foregroundColor(.appText)
                    Spacer()
                    Text(profile.isPro ? "Pro" : "Free")
                        .font(AppFonts.captionEmphasized)
                        .foregroundColor(profile.isPro ? .appAccent : .appTextSecondary)
                }
            }
        }
    }

    // MARK: - Section 2: Preferences
    private var preferencesSection: some View {
        AppCard {
            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                Text("Preferences")
                    .font(AppFonts.headline)
                    .foregroundColor(.appText)

                Divider()

                HStack {
                    Text("Water Unit")
                        .font(AppFonts.body)
                        .foregroundColor(.appText)
                    Spacer()
                    Picker("Water Unit", selection: $settings.waterUnit) {
                        ForEach(WaterUnit.allCases, id: \.self) { unit in
                            Text(unit.label).tag(unit)
                        }
                    }
                    .pickerStyle(.menu)
                    .tint(.appAccent)
                }

                Divider()

                HStack {
                    Text("Reminders")
                        .font(AppFonts.body)
                        .foregroundColor(.appText)
                    Spacer()
                    Toggle("", isOn: Binding(
                        get: { UserDefaults.standard.bool(forKey: "remindersEnabled") },
                        set: { UserDefaults.standard.set($0, forKey: "remindersEnabled") }
                    ))
                    .tint(.appAccent)
                    .labelsHidden()
                }

                Divider()

                HStack {
                    Text("Dark Mode")
                        .font(AppFonts.body)
                        .foregroundColor(.appText)
                    Spacer()
                    Toggle("", isOn: Binding(
                        get: { UserDefaults.standard.bool(forKey: "useDarkMode") },
                        set: { UserDefaults.standard.set($0, forKey: "useDarkMode") }
                    ))
                    .tint(.appAccent)
                    .labelsHidden()
                }
            }
        }
    }

    // MARK: - Section 3: Goals
    private var goalsSection: some View {
        AppCard {
            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                Text("Goals")
                    .font(AppFonts.headline)
                    .foregroundColor(.appText)

                Divider()

                VStack(alignment: .leading, spacing: AppSpacing.xs) {
                    Text("Daily Water Goal (glasses)")
                        .font(AppFonts.footnote)
                        .foregroundColor(.appTextSecondary)
                    AppTextField(placeholder: "8", text: $waterGoalText, keyboardType: .numberPad)
                        .onChange(of: waterGoalText) { _, val in
                            if let n = Int(val) { settings.waterGoalGlasses = n }
                        }
                }

                VStack(alignment: .leading, spacing: AppSpacing.xs) {
                    Text("Daily Step Goal")
                        .font(AppFonts.footnote)
                        .foregroundColor(.appTextSecondary)
                    AppTextField(placeholder: "10000", text: $stepGoalText, keyboardType: .numberPad)
                        .onChange(of: stepGoalText) { _, val in
                            if let n = Int(val) { settings.stepGoal = n }
                        }
                }
            }
        }
    }

    // MARK: - Section 4: Data & Privacy
    private var dataPrivacySection: some View {
        AppCard {
            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                Text("Data & Privacy")
                    .font(AppFonts.headline)
                    .foregroundColor(.appText)

                Divider()

                // Export CSV
                if let csv = try? exportViewModel.csvExport() {
                    ShareLink(
                        item: csv,
                        subject: Text("Nudge Notes Export"),
                        message: Text("Exported from Nudge Notes")
                    ) {
                        HStack {
                            Text("Export Data (CSV)")
                                .font(AppFonts.body)
                                .foregroundColor(.appAccent)
                            Spacer()
                            Image(systemName: "square.and.arrow.up")
                                .foregroundColor(.appAccent)
                        }
                    }
                } else {
                    Button {
                        isPresentingUpgrade = true
                    } label: {
                        HStack {
                            Text("Export Data (CSV)")
                                .font(AppFonts.body)
                                .foregroundColor(.appAccent)
                            Spacer()
                            Text("Pro")
                                .font(AppFonts.footnote)
                                .foregroundColor(.white)
                                .padding(.horizontal, AppSpacing.sm)
                                .padding(.vertical, AppSpacing.xs)
                                .background(Color.appAccent)
                                .clipShape(Capsule())
                        }
                    }
                    .buttonStyle(.plain)
                }

                Divider()

                // Restore / Upgrade
                if profile.isPro {
                    Button("Restore Purchases") {
                        Task { await subscriptionStore.restorePurchases(modelContext: modelContext) }
                    }
                    .font(AppFonts.body)
                    .foregroundColor(.appAccent)

                    if let msg = subscriptionStore.statusMessage {
                        Text(msg)
                            .font(AppFonts.footnote)
                            .foregroundColor(.appTextSecondary)
                    }
                } else {
                    Button {
                        isPresentingUpgrade = true
                    } label: {
                        HStack {
                            Text("Upgrade to Pro")
                                .font(AppFonts.bodyEmphasized)
                                .foregroundColor(.appAccent)
                            Spacer()
                            Image(systemName: "star.fill")
                                .foregroundColor(.appAccent)
                        }
                    }
                    .buttonStyle(.plain)
                }

                Divider()

                // Delete all data
                Button {
                    isPresentingDeleteConfirm = true
                } label: {
                    HStack {
                        Text("Delete All Data")
                            .font(AppFonts.body)
                            .foregroundColor(.red)
                        Spacer()
                        Image(systemName: "trash")
                            .foregroundColor(.red)
                    }
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - Section 5: Support
    private var supportSection: some View {
        AppCard {
            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                Text("Support")
                    .font(AppFonts.headline)
                    .foregroundColor(.appText)

                Divider()

                HStack {
                    Text("Version")
                        .font(AppFonts.body)
                        .foregroundColor(.appText)
                    Spacer()
                    Text(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0")
                        .font(AppFonts.caption)
                        .foregroundColor(.appTextSecondary)
                }

                Divider()

                HStack {
                    Text("Build")
                        .font(AppFonts.body)
                        .foregroundColor(.appText)
                    Spacer()
                    Text(Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1")
                        .font(AppFonts.caption)
                        .foregroundColor(.appTextSecondary)
                }

                Divider()

                Link(destination: URL(string: "https://apps.apple.com/account/subscriptions")!) {
                    HStack {
                        Text("Manage Subscription")
                            .font(AppFonts.body)
                            .foregroundColor(.appAccent)
                        Spacer()
                        Image(systemName: "arrow.up.right")
                            .font(AppFonts.footnote)
                            .foregroundColor(.appAccent)
                    }
                }
            }
        }
    }

    // MARK: - Helpers
    private func deleteAllData() {
        try? modelContext.delete(model: DailyLog.self)
        try? modelContext.delete(model: MonthlyReview.self)
        try? modelContext.save()
    }
}
