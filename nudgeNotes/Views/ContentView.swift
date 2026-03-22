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
                        let isSeededOnboarded = ProcessInfo.processInfo.arguments.contains("-ui-testing-seed-onboarded")
                        modelContext.insert(
                            UserProfile(
                                onboardingCompleted: isSeededOnboarded,
                                goals: isSeededOnboarded ? ["Sleep", "Movement"] : []
                            )
                        )
                        try? modelContext.save()
                    }
            }
        }
    }
}
