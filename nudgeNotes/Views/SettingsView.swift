import SwiftUI
import SwiftData

struct SettingsView: View {
    let profile: UserProfile

    @Environment(\.modelContext) private var modelContext
    @State private var isPresentingUpgrade = false
    @State private var subscriptionStore: SubscriptionStore

    init(profile: UserProfile) {
        self.profile = profile
        _subscriptionStore = State(initialValue: SubscriptionStore(profile: profile))
    }

    var body: some View {
        NavigationStack {
            List {
                Section("Membership") {
                    LabeledContent("Plan", value: profile.isPro ? "Pro" : "Free")
                    if let statusMessage = subscriptionStore.statusMessage {
                        Text(statusMessage)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }

                    if profile.isPro {
                        Button("Restore Purchases") {
                            Task {
                                await subscriptionStore.restorePurchases(modelContext: modelContext)
                            }
                        }
                        Link("Manage Subscriptions", destination: URL(string: "https://apps.apple.com/account/subscriptions")!)
                    } else {
                        Button("Upgrade to Pro") {
                            isPresentingUpgrade = true
                        }
                    }
                }

                Section("What Pro unlocks") {
                    Text("Insights charts and patterns")
                    Text("CSV export")
                    Text("Restore purchases")
                }
            }
            .navigationTitle("Settings")
            .sheet(isPresented: $isPresentingUpgrade) {
                ProUpgradeView(profile: profile)
            }
            .task {
                await subscriptionStore.loadProducts(modelContext: modelContext)
            }
        }
    }
}
