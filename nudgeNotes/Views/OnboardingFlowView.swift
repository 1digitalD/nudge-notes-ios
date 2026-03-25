import SwiftUI
import SwiftData

struct OnboardingFlowView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel: OnboardingViewModel
    private let permissionManager: PermissionManaging
    @StateObject private var healthKit = HealthKitManager.shared

    init(profile: UserProfile, permissionManager: PermissionManaging) {
        _viewModel = State(initialValue: OnboardingViewModel(profile: profile))
        self.permissionManager = permissionManager
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                progressHeader

                ScrollView {
                    currentStepView
                }

                if viewModel.step != .complete {
                    primaryAction
                }
            }
            .padding(24)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .background(Color.appBackground.ignoresSafeArea())
        }
    }

    @ViewBuilder
    private var currentStepView: some View {
        switch viewModel.step {
        case .welcome:
            WelcomeView()
        case .profile:
            OnboardingProfileView(viewModel: viewModel)
        case .goals:
            OnboardingGoalsView(viewModel: viewModel)
        case .healthKit:
            OnboardingHealthKitView(healthKit: healthKit, viewModel: viewModel, permissionManager: permissionManager)
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
                .tint(Color.appAccent)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var primaryAction: some View {
        Button(action: { viewModel.advance() }) {
            Text(buttonTitle)
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 6)
        }
        .buttonStyle(.borderedProminent)
        .tint(viewModel.canContinue ? Color.appAccent : .gray.opacity(0.35))
        .disabled(!viewModel.canContinue)
        .accessibilityIdentifier(buttonIdentifier)
        .accessibilityLabel(buttonTitle)
    }

    private var buttonTitle: String {
        switch viewModel.step {
        case .welcome:
            return "Get Started"
        case .profile:
            return "Continue"
        case .goals:
            return "Continue"
        case .healthKit:
            return "Finish Setup"
        case .complete:
            return ""
        }
    }

    private var buttonIdentifier: String {
        switch viewModel.step {
        case .welcome:
            return "welcome-continue-button"
        case .profile:
            return "profile-continue-button"
        case .goals:
            return "goals-continue-button"
        case .healthKit:
            return "healthkit-continue-button"
        case .complete:
            return "finish-onboarding-button"
        }
    }
}

// MARK: - Screen 1: Welcome

private struct WelcomeView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Welcome to nudge Notes")
                .font(.system(.largeTitle, design: .rounded, weight: .bold))
                .accessibilityIdentifier("welcome-title")

            Text("A calm place to track your waist-to-hip ratio, small habits, and daily signals without streak pressure.")
                .font(.body)
                .foregroundStyle(.secondary)

            Spacer().frame(height: 16)

            Label("Track sleep, meals, movement & mood", systemImage: "heart.text.square")
            Label("Weekly weigh-ins with WHR tracking", systemImage: "ruler")
            Label("Optional goals — no pressure", systemImage: "checkmark.circle")
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Screen 2: Profile

private struct OnboardingProfileView: View {
    @Bindable var viewModel: OnboardingViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Let's personalize your experience")
                .font(.system(.title2, design: .rounded, weight: .bold))
                .accessibilityIdentifier("profile-title")

            VStack(spacing: AppSpacing.md) {
                // Name
                VStack(alignment: .leading, spacing: AppSpacing.xs) {
                    Text("Name (optional)")
                        .font(AppFonts.footnote)
                        .foregroundStyle(.secondary)
                    AppTextField(placeholder: "Your name", text: $viewModel.nameText)
                }

                // Weight
                VStack(alignment: .leading, spacing: AppSpacing.xs) {
                    Text("Current Weight (for water goal)")
                        .font(AppFonts.footnote)
                        .foregroundStyle(.secondary)
                    HStack {
                        AppTextField(placeholder: "165", text: $viewModel.weightText, keyboardType: .decimalPad)
                        Text("lbs")
                            .font(AppFonts.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                // Height
                VStack(alignment: .leading, spacing: AppSpacing.xs) {
                    Text("Height (optional)")
                        .font(AppFonts.footnote)
                        .foregroundStyle(.secondary)
                    HStack(spacing: AppSpacing.sm) {
                        AppTextField(placeholder: "5", text: $viewModel.heightFeetText, keyboardType: .numberPad)
                        Text("ft")
                            .font(AppFonts.caption)
                            .foregroundStyle(.secondary)
                        AppTextField(placeholder: "10", text: $viewModel.heightInchesText, keyboardType: .numberPad)
                        Text("in")
                            .font(AppFonts.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .padding()
            .background(Color.appCard)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

            if let weight = Double(viewModel.weightText), weight > 0 {
                Text("Based on \(Int(weight)) lbs, we'll suggest \(viewModel.smartWaterGlasses) glasses of water/day")
                    .font(AppFonts.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Screen 3: Goals

private struct OnboardingGoalsView: View {
    @Bindable var viewModel: OnboardingViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Set your daily goals")
                .font(.system(.title2, design: .rounded, weight: .bold))
                .accessibilityIdentifier("goals-title")

            Text("These are optional. You can adjust anytime in Settings.")
                .font(AppFonts.caption)
                .foregroundStyle(.secondary)

            // Water goal
            goalCard(
                icon: "drop.fill",
                title: "Water Goal",
                isEnabled: $viewModel.settings.waterGoalEnabled
            ) {
                HStack {
                    Text("\(viewModel.settings.waterGoalGlasses) glasses")
                        .font(AppFonts.bodyEmphasized)
                    Text("(\(viewModel.settings.waterGoalGlasses * 8) oz)")
                        .font(AppFonts.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                }
                Slider(
                    value: Binding(
                        get: { Double(viewModel.settings.waterGoalGlasses) },
                        set: { viewModel.settings.waterGoalGlasses = Int($0) }
                    ),
                    in: 4...16,
                    step: 1
                )
                .tint(Color.appAccent)
            }

            // Steps goal
            goalCard(
                icon: "figure.walk",
                title: "Steps Goal",
                isEnabled: $viewModel.settings.stepGoalEnabled
            ) {
                HStack(spacing: AppSpacing.sm) {
                    ForEach([6000, 8000, 10000, 12000], id: \.self) { goal in
                        Button {
                            viewModel.settings.stepGoal = goal
                        } label: {
                            Text("\(goal / 1000)k")
                                .font(AppFonts.caption)
                                .foregroundStyle(viewModel.settings.stepGoal == goal ? Color.white : Color.appText)
                                .padding(.horizontal, AppSpacing.sm)
                                .padding(.vertical, AppSpacing.xs)
                                .background(
                                    RoundedRectangle(cornerRadius: 6)
                                        .fill(viewModel.settings.stepGoal == goal ? Color.appAccent : Color.clear)
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 6)
                                        .stroke(Color.appBorder, lineWidth: 1)
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            // Sleep goal
            goalCard(
                icon: "bed.double.fill",
                title: "Sleep Goal",
                isEnabled: $viewModel.settings.sleepGoalEnabled
            ) {
                HStack {
                    Text("\(Int(viewModel.settings.sleepGoalHours)) hours")
                        .font(AppFonts.bodyEmphasized)
                    Spacer()
                }
                Slider(
                    value: $viewModel.settings.sleepGoalHours,
                    in: 5...10,
                    step: 0.5
                )
                .tint(Color.appAccent)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder
    private func goalCard<Content: View>(
        icon: String,
        title: String,
        isEnabled: Binding<Bool>,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            HStack {
                Image(systemName: icon)
                    .foregroundStyle(Color.appAccent)
                Text(title)
                    .font(AppFonts.headline)
                Spacer()
                Toggle("", isOn: isEnabled)
                    .tint(Color.appAccent)
                    .labelsHidden()
            }

            if isEnabled.wrappedValue {
                content()
            }
        }
        .padding()
        .background(Color.appCard)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

// MARK: - Screen 4: HealthKit

private struct OnboardingHealthKitView: View {
    @ObservedObject var healthKit: HealthKitManager
    @Bindable var viewModel: OnboardingViewModel
    let permissionManager: PermissionManaging

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            if healthKit.isAvailable {
                VStack(spacing: AppSpacing.md) {
                    Image(systemName: "heart.circle.fill")
                        .font(.system(size: 64))
                        .foregroundStyle(Color.appAccent)

                    Text("Connect Apple Health")
                        .font(.system(.title2, design: .rounded, weight: .bold))

                    Text("Auto-sync your steps, workouts, and sleep for effortless tracking.")
                        .font(AppFonts.body)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)

                VStack(alignment: .leading, spacing: AppSpacing.sm) {
                    permissionRow(icon: "figure.walk", label: "Steps")
                    permissionRow(icon: "bed.double", label: "Sleep")
                    permissionRow(icon: "figure.strengthtraining.traditional", label: "Workouts")
                    permissionRow(icon: "scalemass", label: "Weight (optional)")
                }
                .padding()
                .background(Color.appCard)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

                if !healthKit.isAuthorized {
                    Button {
                        Task { await healthKit.requestAuthorization() }
                    } label: {
                        Text("Connect Health")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 6)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(Color.appAccent)
                } else {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(Color.appSuccess)
                        Text("Connected to Apple Health")
                            .font(AppFonts.bodyEmphasized)
                    }
                    .frame(maxWidth: .infinity)
                }
            }

            Divider()

            // Also keep photo/notification permissions
            Text("Optional permissions")
                .font(AppFonts.headline)

            permissionButton(
                title: "Photo access",
                status: viewModel.photoPermissionStatus
            ) {
                Task {
                    viewModel.photoPermissionStatus = await permissionManager.requestPhotoPermission()
                }
            }

            permissionButton(
                title: "Notifications",
                status: viewModel.notificationPermissionStatus
            ) {
                Task {
                    viewModel.notificationPermissionStatus = await permissionManager.requestNotificationPermission()
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder
    private func permissionRow(icon: String, label: String) -> some View {
        HStack(spacing: AppSpacing.sm) {
            Image(systemName: icon)
                .foregroundStyle(Color.appAccent)
                .frame(width: 24)
            Text(label)
                .font(AppFonts.body)
        }
    }

    @ViewBuilder
    private func permissionButton(title: String, status: PermissionStatus, action: @escaping () -> Void) -> some View {
        HStack {
            Text(title)
                .font(AppFonts.body)
            Spacer()
            if status == .granted {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(Color.appSuccess)
            } else {
                Button("Allow") { action() }
                    .buttonStyle(.borderedProminent)
                    .tint(Color.appAccent)
            }
        }
        .padding()
        .background(Color.appCard)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

// MARK: - Completion

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
            .tint(Color.appAccent)
            .accessibilityIdentifier("finish-onboarding-button")
            .accessibilityLabel("Finish onboarding")
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
