import SwiftUI

struct HomeView: View {
    let profile: UserProfile

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 16) {
                Text("Today, gently")
                    .font(.title3.weight(.medium))
                    .foregroundStyle(.secondary)

                Text("Home")
                    .font(.largeTitle.weight(.semibold))
                    .accessibilityIdentifier("home-title")

                if profile.goals.isEmpty {
                    Text("Start with a quick check-in when you're ready.")
                        .foregroundStyle(.secondary)
                } else {
                    Text("Current focus: \(profile.goals.joined(separator: ", "))")
                        .foregroundStyle(.secondary)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .padding(24)
            .background(Color(.systemGroupedBackground))
        }
    }
}
