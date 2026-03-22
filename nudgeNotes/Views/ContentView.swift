import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \UserProfile.createdAt) private var profiles: [UserProfile]

    var body: some View {
        Group {
            if let profile = profiles.first {
                if profile.onboardingCompleted {
                    HomeView(profile: profile)
                } else {
                    OnboardingFlowView(
                        profile: profile,
                        permissionManager: SystemPermissionManager.makeDefault()
                    )
                }
            } else {
                ProgressView()
                    .task {
                        guard profiles.isEmpty else { return }
                        modelContext.insert(UserProfile())
                        try? modelContext.save()
                    }
            }
        }
    }
}
