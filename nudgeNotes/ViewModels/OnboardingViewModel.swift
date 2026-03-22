import Foundation
import Observation

enum OnboardingStep: Int, CaseIterable {
    case welcome
    case explainer
    case goals
    case permissions
    case complete
}

@Observable
final class OnboardingViewModel {
    let profile: UserProfile

    var step: OnboardingStep = .welcome
    var selectedGoals: [String]
    var photoPermissionStatus: PermissionStatus = .notRequested
    var notificationPermissionStatus: PermissionStatus = .notRequested

    let goalOptions = [
        "Sleep",
        "Movement",
        "Stress",
        "Hydration",
        "Nutrition",
        "Consistency"
    ]

    init(profile: UserProfile) {
        self.profile = profile
        self.selectedGoals = profile.goals
    }

    var canContinue: Bool {
        switch step {
        case .goals:
            return !selectedGoals.isEmpty
        case .complete:
            return false
        default:
            return true
        }
    }

    func advance() {
        guard canContinue else { return }
        switch step {
        case .welcome:
            step = .explainer
        case .explainer:
            step = .goals
        case .goals:
            step = .permissions
        case .permissions, .complete:
            break
        }
    }

    func toggleGoal(_ goal: String) {
        if selectedGoals.contains(goal) {
            selectedGoals.removeAll { $0 == goal }
            return
        }

        guard selectedGoals.count < 3 else { return }
        selectedGoals.append(goal)
    }

    func completeOnboarding() {
        profile.goals = selectedGoals
        profile.onboardingCompleted = true
        step = .complete
    }
}
