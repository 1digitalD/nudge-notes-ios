import SwiftUI
import SwiftData

struct HomeView: View {
    let profile: UserProfile
    @State private var selectedDate = Date()
    @State private var isPresentingCheckIn = false
    @State private var isPresentingWHR = false
    @State private var isPresentingPhotoLog = false

    var body: some View {
        TabView {
            homeDashboard
                .tabItem {
                    Label("Home", systemImage: "house")
                }

            HistoryTabView(profile: profile)
                .tabItem {
                    Label("History", systemImage: "calendar")
                }

            InsightsView(profile: profile)
                .tabItem {
                    Label("Insights", systemImage: "chart.xyaxis.line")
                }

            SettingsView(profile: profile)
                .tabItem {
                    Label("Settings", systemImage: "gearshape")
                }
        }
    }

    private var homeDashboard: some View {
        HomeDashboardView(
            profile: profile,
            selectedDate: $selectedDate,
            isPresentingCheckIn: $isPresentingCheckIn,
            isPresentingWHR: $isPresentingWHR,
            isPresentingPhotoLog: $isPresentingPhotoLog
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
    }

}

private struct HomeDashboardView: View {
    let profile: UserProfile
    @Binding var selectedDate: Date
    @Binding var isPresentingCheckIn: Bool
    @Binding var isPresentingWHR: Bool
    @Binding var isPresentingPhotoLog: Bool

    @Query(sort: \DailyLog.date, order: .reverse) private var dailyLogs: [DailyLog]
    @Query(sort: \WHREntry.date, order: .reverse) private var whrEntries: [WHREntry]

    private var summary: HomeViewModel {
        HomeViewModel(dailyLogs: dailyLogs, whrEntries: whrEntries)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("Home")
                        .font(.largeTitle.weight(.semibold))
                        .accessibilityIdentifier("home-title")
                        .accessibilityAddTraits(.isHeader)

                    Text(profile.goals.isEmpty ? "Start with a quick check-in when you're ready." : "Current focus: \(profile.goals.joined(separator: ", "))")
                        .foregroundStyle(.secondary)

                    DatePicker("Selected day", selection: $selectedDate, displayedComponents: .date)
                        .datePickerStyle(.compact)

                    HStack(spacing: 12) {
                        summaryCard(title: "Current WHR", value: summary.latestWHRText, identifier: "current-whr-value")
                        summaryCard(title: "Days logged", value: "\(summary.loggedDaysCount)", identifier: "logged-days-value")
                    }

                    HStack(spacing: 12) {
                        summaryCard(title: "Current streak", value: "\(summary.currentStreak)", identifier: "streak-value")
                        summaryCard(title: "Photos", value: "\(summary.photoCount)", identifier: "photo-count-value")
                    }

                    VStack(spacing: 12) {
                        Button("Check in for today") {
                            isPresentingCheckIn = true
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(AppTheme.accent)
                        .accessibilityIdentifier("check-in-button")
                        .accessibilityLabel("Check in for selected day")

                        HStack(spacing: 12) {
                            Button("WHR Calculator") {
                                isPresentingWHR = true
                            }
                            .buttonStyle(.bordered)
                            .tint(AppTheme.accent)
                            .accessibilityIdentifier("whr-calculator-button")
                            .accessibilityLabel("Open WHR calculator")

                            Button("Photo Log") {
                                isPresentingPhotoLog = true
                            }
                            .buttonStyle(.bordered)
                            .tint(AppTheme.accent)
                            .accessibilityLabel("Open photo log")
                        }
                    }
                }
            }
            .padding(24)
            .background(AppTheme.background)
            .refreshable {
            }
        }
    }

    private func summaryCard(title: String, value: String, identifier: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.title2.weight(.semibold))
                .accessibilityIdentifier(identifier)
                .accessibilityLabel(title)
                .accessibilityValue(value)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(AppTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(AppTheme.divider, lineWidth: 1)
        )
    }
}
