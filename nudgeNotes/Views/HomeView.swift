import SwiftUI
import SwiftData

struct HomeView: View {
    let profile: UserProfile

    var body: some View {
        TabView {
            DashboardView(profile: profile)
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
