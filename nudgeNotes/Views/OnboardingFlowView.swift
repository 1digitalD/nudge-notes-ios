import SwiftUI
import SwiftData

struct OnboardingFlowView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel: OnboardingViewModel
    private let permissionManager: PermissionManaging

    init(profile: UserProfile, permissionManager: PermissionManaging) {
        _viewModel = State(initialValue: OnboardingViewModel(profile: profile))
        self.permissionManager = permissionManager
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                progressHeader

                currentStepView

                if viewModel.step != .complete {
                    primaryAction
                }
            }
            .padding(24)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .background(AppTheme.background.ignoresSafeArea())
        }
    }

    @ViewBuilder
    private var currentStepView: some View {
        switch viewModel.step {
        case .welcome:
            WelcomeView()
        case .explainer:
            WHRExplainerView()
        case .goals:
            GoalSelectionView(viewModel: viewModel)
        case .permissions:
            PermissionsView(viewModel: viewModel, permissionManager: permissionManager)
        case .complete:
            OnboardingCompletionView {
                viewModel.completeOnboarding()
                try? modelContext.save()
            }
        }
    }

    private var progressHeader: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("nudge Notes")
                .font(.system(.title, design: .rounded, weight: .bold))
                .dynamicTypeSize(...DynamicTypeSize.xxxLarge)

            ProgressView(value: Double(viewModel.step.rawValue), total: Double(OnboardingStep.allCases.count - 1))
                .tint(AppTheme.accent)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var primaryAction: some View {
        Button(action: advanceStep) {
            Text(buttonTitle)
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 6)
        }
        .buttonStyle(.borderedProminent)
        .tint(viewModel.canContinue ? AppTheme.accent : .gray.opacity(0.35))
        .disabled(!viewModel.canContinue)
        .accessibilityIdentifier(buttonIdentifier)
        .accessibilityLabel(buttonTitle)
    }

    private var buttonTitle: String {
        switch viewModel.step {
        case .welcome:
            return "Get Started"
        case .explainer:
            return "Keep Going"
        case .goals:
            return "Continue"
        case .permissions:
            return "Review Complete"
        case .complete:
            return ""
        }
    }

    private var buttonIdentifier: String {
        switch viewModel.step {
        case .welcome:
            return "welcome-continue-button"
        case .explainer:
            return "explainer-continue-button"
        case .goals:
            return "goals-continue-button"
        case .permissions:
            return "permissions-continue-button"
        case .complete:
            return "finish-onboarding-button"
        }
    }

    private func advanceStep() {
        if viewModel.step == .permissions {
            viewModel.step = .complete
            return
        }
        viewModel.advance()
    }
}

private struct WelcomeView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Welcome to nudge Notes")
                .font(.system(.largeTitle, design: .rounded, weight: .bold))
                .accessibilityIdentifier("welcome-title")

            Text("A calm place to track your waist-to-hip ratio, small habits, and daily signals without streak pressure.")
                .font(.body)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct WHRExplainerView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Why WHR?")
                .font(.system(.title, design: .rounded, weight: .bold))
                .accessibilityIdentifier("explainer-title")

            Text("Waist-to-hip ratio can reveal body-shape trends more clearly than weight alone. nudge Notes keeps the context gentle: measure, notice patterns, and adjust with compassion.")
                .foregroundStyle(.secondary)

            Label("Measure waist at the narrowest point", systemImage: "ruler")
            Label("Measure hips at the widest point", systemImage: "figure.walk")
            Label("Log alongside sleep, stress, and movement", systemImage: "heart.text.square")
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct GoalSelectionView: View {
    @Bindable var viewModel: OnboardingViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("What would you like to support first?")
                .font(.system(.title2, design: .rounded, weight: .bold))
                .accessibilityIdentifier("goal-selection-title")

            Text("Choose up to three focus areas. You can change these later.")
                .foregroundStyle(.secondary)

            ForEach(viewModel.goalOptions, id: \.self) { goal in
                Button {
                    viewModel.toggleGoal(goal)
                } label: {
                    HStack {
                        Text(goal)
                        Spacer()
                        Image(systemName: viewModel.selectedGoals.contains(goal) ? "checkmark.circle.fill" : "circle")
                    }
                    .padding()
                    .background(AppTheme.cardBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
                .buttonStyle(.bordered)
                .tint(viewModel.selectedGoals.contains(goal) ? AppTheme.accent : AppTheme.mint)
                .accessibilityIdentifier("goal-option-\(goal)")
                .accessibilityLabel(goal)
                .accessibilityValue(viewModel.selectedGoals.contains(goal) ? "Selected" : "Not selected")
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct PermissionsView: View {
    @Bindable var viewModel: OnboardingViewModel
    let permissionManager: PermissionManaging

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Optional permissions")
                .font(.system(.title2, design: .rounded, weight: .bold))
                .accessibilityIdentifier("permissions-title")

            Text("Photos let you keep visual logs. Notifications can offer a gentle reminder. Both are optional.")
                .foregroundStyle(.secondary)

            permissionRow(
                title: "Photo access",
                status: viewModel.photoPermissionStatus,
                action: requestPhotoPermission,
                identifier: "photo-permission-button"
            )

            permissionRow(
                title: "Notifications",
                status: viewModel.notificationPermissionStatus,
                action: requestNotificationPermission,
                identifier: "notification-permission-button"
            )
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func permissionRow(
        title: String,
        status: PermissionStatus,
        action: @escaping () -> Void,
        identifier: String
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
            Text(status.description)
                .foregroundStyle(.secondary)
            Button("Allow") {
                action()
            }
            .buttonStyle(.borderedProminent)
            .tint(AppTheme.accent)
            .accessibilityIdentifier(identifier)
        }
        .padding()
        .background(AppTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private func requestPhotoPermission() {
        Task {
            viewModel.photoPermissionStatus = await permissionManager.requestPhotoPermission()
        }
    }

    private func requestNotificationPermission() {
        Task {
            viewModel.notificationPermissionStatus = await permissionManager.requestNotificationPermission()
        }
    }
}

private struct OnboardingCompletionView: View {
    let finish: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("You're ready")
                .font(.system(.title, design: .rounded, weight: .bold))
                .accessibilityIdentifier("completion-title")

            Text("Your first home screen is ready. Start with a small check-in and let the app stay light.")
                .foregroundStyle(.secondary)

            Button("Finish") {
                finish()
            }
            .buttonStyle(.borderedProminent)
            .tint(AppTheme.accent)
            .accessibilityIdentifier("finish-onboarding-button")
            .accessibilityLabel("Finish onboarding")
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
