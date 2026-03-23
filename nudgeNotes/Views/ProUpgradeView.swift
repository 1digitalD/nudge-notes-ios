import SwiftUI
import SwiftData

struct ProUpgradeView: View {
    let profile: UserProfile

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @State private var subscriptionStore: SubscriptionStore

    init(profile: UserProfile) {
        self.profile = profile
        _subscriptionStore = State(initialValue: SubscriptionStore(profile: profile))
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("Upgrade to Pro")
                        .font(.largeTitle.weight(.bold))
                        .accessibilityAddTraits(.isHeader)

                    Text("Unlock insights, CSV export, and a calmer long-term view of your progress.")
                        .foregroundStyle(.secondary)

                    featureList
                    planPicker
                    purchaseActions

                    if let statusMessage = subscriptionStore.statusMessage {
                        Text(statusMessage)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(24)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Nudge Notes Pro")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Close") {
                        dismiss()
                    }
                    .buttonStyle(.bordered)
                    .tint(AppTheme.accent)
                }
            }
            .task {
                await subscriptionStore.loadProducts(modelContext: modelContext)
            }
        }
    }

    private var featureList: some View {
        VStack(alignment: .leading, spacing: 12) {
            ProFeatureRow(title: "Insights", freeValue: "Preview only", proValue: "Charts, weekly summaries, trends")
            ProFeatureRow(title: "CSV export", freeValue: "Locked", proValue: "Export your tracking data")
            ProFeatureRow(title: "Restore purchases", freeValue: "N/A", proValue: "Available any time")
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    private var planPicker: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Choose a plan")
                .font(.headline)

            ForEach(subscriptionStore.products) { product in
                Button {
                    if let plan = product.plan {
                        subscriptionStore.selectedPlan = plan
                    }
                } label: {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(product.displayName)
                                .font(.headline)
                            Text("\(product.displayPrice) / \(product.subscriptionPeriod)")
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        if subscriptionStore.selectedPlan.productID == product.id {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(Color.accentColor)
                        } else {
                            Image(systemName: "circle")
                                .foregroundStyle(.tertiary)
                        }
                    }
                    .padding()
                    .background(Color(.secondarySystemGroupedBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
                .buttonStyle(.bordered)
                .tint(subscriptionStore.selectedPlan.productID == product.id ? AppTheme.accent : AppTheme.mint)
                .accessibilityLabel("\(product.displayName), \(product.displayPrice) per \(product.subscriptionPeriod)")
            }

            if subscriptionStore.products.isEmpty {
                ForEach(SubscriptionPlan.allCases) { plan in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(plan.title)
                            .font(.headline)
                        Text(plan.subtitle)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(Color(.secondarySystemGroupedBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
            }
        }
    }

    private var purchaseActions: some View {
        VStack(alignment: .leading, spacing: 12) {
            Button {
                Task {
                    await subscriptionStore.purchaseSelectedPlan(modelContext: modelContext)
                    if profile.isPro {
                        dismiss()
                    }
                }
            } label: {
                if subscriptionStore.isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                } else {
                    Text("Start Pro")
                        .frame(maxWidth: .infinity)
                }
            }
            .buttonStyle(.borderedProminent)
            .tint(AppTheme.accent)
            .controlSize(.large)

            Button("Restore Purchases") {
                Task {
                    await subscriptionStore.restorePurchases(modelContext: modelContext)
                }
            }
            .buttonStyle(.bordered)
            .tint(AppTheme.accent)
        }
    }
}

private struct ProFeatureRow: View {
    let title: String
    let freeValue: String
    let proValue: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.headline)
            HStack {
                Text("Free")
                    .foregroundStyle(.secondary)
                Spacer()
                Text(freeValue)
                    .foregroundStyle(.secondary)
            }
            HStack {
                Text("Pro")
                    .foregroundStyle(.secondary)
                Spacer()
                Text(proValue)
                    .multilineTextAlignment(.trailing)
            }
        }
    }
}
