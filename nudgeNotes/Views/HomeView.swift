import SwiftUI
import SwiftData

struct HomeView: View {
    let profile: UserProfile
    @State private var selectedDate = Date()
    @State private var isPresentingCheckIn = false
    @State private var isPresentingWHR = false
    @State private var isPresentingPhotoLog = false
    @State private var isPresentingWeeklyWeighIn = false

    var body: some View {
        TabView {
            HomeDashboardView(
                profile: profile,
                selectedDate: $selectedDate,
                isPresentingCheckIn: $isPresentingCheckIn,
                isPresentingWHR: $isPresentingWHR,
                isPresentingPhotoLog: $isPresentingPhotoLog,
                isPresentingWeeklyWeighIn: $isPresentingWeeklyWeighIn
            )
            .sheet(isPresented: $isPresentingCheckIn) {
                DailyCheckInView(date: selectedDate)
            }
            .sheet(isPresented: $isPresentingWHR) {
                WHRCalculatorView(date: selectedDate)
            }
            .sheet(isPresented: $isPresentingPhotoLog) {
                PhotoLoggingView(date: selectedDate)
            }
            .sheet(isPresented: $isPresentingWeeklyWeighIn) {
                WeeklyWeighInView(date: selectedDate)
            }
            .tabItem {
                Label("Home", systemImage: "house")
            }

            InsightsTabView()
                .tabItem {
                    Label("Insights", systemImage: "chart.bar.fill")
                }

            HistoryTabView(profile: profile)
                .tabItem {
                    Label("History", systemImage: "calendar")
                }

            SettingsView(profile: profile)
                .tabItem {
                    Label("Settings", systemImage: "gearshape")
                }
        }
        .tint(.appAccent)
    }
}

// MARK: - Dashboard

private struct HomeDashboardView: View {
    let profile: UserProfile
    @Binding var selectedDate: Date
    @Binding var isPresentingCheckIn: Bool
    @Binding var isPresentingWHR: Bool
    @Binding var isPresentingPhotoLog: Bool
    @Binding var isPresentingWeeklyWeighIn: Bool

    @Query(sort: \DailyLog.date, order: .reverse) private var dailyLogs: [DailyLog]
    @Query(sort: \WHREntry.date, order: .reverse) private var whrEntries: [WHREntry]

    private var summary: HomeViewModel {
        HomeViewModel(dailyLogs: dailyLogs, whrEntries: whrEntries)
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
        switch hour {
        case 6..<18: return "☀️"
        default:     return "🌙"
        }
    }

    private var todayDateString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMMM d"
        return formatter.string(from: Date())
    }

    private var daysLoggedThisMonth: Int {
        let cal = Calendar.current
        let now = Date()
        guard let monthStart = cal.date(from: cal.dateComponents([.year, .month], from: now)) else {
            return 0
        }
        let thisMonthLogs = dailyLogs.filter { $0.date >= monthStart && $0.date <= now }
        return Set(thisMonthLogs.map { cal.startOfDay(for: $0.date) }).count
    }

    private var daysInMonthSoFar: Int {
        Calendar.current.component(.day, from: Date())
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: AppSpacing.sectionSpacing) {

                    // MARK: Greeting
                    VStack(alignment: .leading, spacing: AppSpacing.xs) {
                        Text("\(greeting) \(greetingEmoji)")
                            .font(AppFonts.title)
                            .foregroundColor(.appText)
                            .accessibilityAddTraits(.isHeader)

                        Text(todayDateString)
                            .font(AppFonts.caption)
                            .foregroundColor(.appTextSecondary)
                    }

                    // MARK: Today's Check-in CTA
                    AppCard {
                        VStack(alignment: .leading, spacing: AppSpacing.md) {
                            HStack {
                                Text("Today's Check-in")
                                    .font(AppFonts.headline)
                                    .foregroundColor(.appText)
                                Spacer()
                                Image(systemName: "pencil.circle.fill")
                                    .font(.title2)
                                    .foregroundColor(.appAccent)
                            }

                            Divider()
                                .background(Color.appBorder)

                            AppButton("Tap to Log") {
                                isPresentingCheckIn = true
                            }
                            .accessibilityIdentifier("check-in-button")
                            .accessibilityLabel("Check in for selected day")
                        }
                    }

                    // MARK: This Month Stats
                    AppCard {
                        VStack(alignment: .leading, spacing: AppSpacing.md) {
                            HStack {
                                Label("This Month", systemImage: "chart.bar.fill")
                                    .font(AppFonts.headline)
                                    .foregroundColor(.appText)
                                Spacer()
                            }

                            Divider()
                                .background(Color.appBorder)

                            VStack(spacing: AppSpacing.sm) {
                                statRow(label: "Days logged",
                                        value: "\(daysLoggedThisMonth) / \(daysInMonthSoFar)",
                                        identifier: "logged-days-value")
                                statRow(label: "Current WHR",
                                        value: summary.latestWHRText,
                                        identifier: "current-whr-value")
                                statRow(label: "Current streak",
                                        value: "\(summary.currentStreak) days",
                                        identifier: "streak-value")
                                statRow(label: "Photos",
                                        value: "\(summary.photoCount)",
                                        identifier: "photo-count-value")
                            }
                        }
                    }

                    // MARK: Quick Actions
                    HStack(spacing: AppSpacing.sm) {
                        AppButton("Weekly Weigh-In", variant: .secondary) {
                            isPresentingWeeklyWeighIn = true
                        }
                        .accessibilityIdentifier("weekly-weighin-button")

                        AppButton("Photos", variant: .secondary) {
                            isPresentingPhotoLog = true
                        }
                    }

                    HStack(spacing: AppSpacing.sm) {
                        AppButton("WHR", variant: .secondary) {
                            isPresentingWHR = true
                        }
                        .accessibilityIdentifier("whr-calculator-button")

                        Spacer()
                    }

                }
                .padding(.horizontal, AppSpacing.screenPadding)
                .padding(.top, AppSpacing.lg)
                .padding(.bottom, AppSpacing.xxl)
            }
            .background(Color.appBackground.ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Nudge Notes")
                        .font(AppFonts.captionEmphasized)
                        .foregroundColor(.appTextSecondary)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    if profile.isPro {
                        Label("Pro", systemImage: "star.fill")
                            .font(AppFonts.footnote)
                            .foregroundColor(.appAccent)
                            .labelStyle(.iconOnly)
                    }
                }
            }
        }
    }

    private func statRow(label: String, value: String, identifier: String) -> some View {
        HStack {
            Text(label)
                .font(AppFonts.caption)
                .foregroundColor(.appTextSecondary)
            Spacer()
            Text(value)
                .font(AppFonts.captionEmphasized)
                .foregroundColor(.appText)
                .accessibilityIdentifier(identifier)
                .accessibilityLabel(label)
                .accessibilityValue(value)
        }
    }
}
