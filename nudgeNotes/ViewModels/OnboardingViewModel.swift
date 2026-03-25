import Foundation
import Observation

enum OnboardingStep: Int, CaseIterable {
    case welcome
    case profile
    case goals
    case healthKit
    case complete
}

@Observable
final class OnboardingViewModel {
    let profile: UserProfile
    var settings: UserSettings

    var step: OnboardingStep = .welcome
    var selectedGoals: [String]
    var photoPermissionStatus: PermissionStatus = .notRequested
    var notificationPermissionStatus: PermissionStatus = .notRequested

    // Profile fields
    var nameText: String = ""
    var weightText: String = ""
    var heightFeetText: String = ""
    var heightInchesText: String = ""

    let goalOptions = [
        "Sleep",
        "Movement",
        "Stress",
        "Hydration",
        "Nutrition",
        "Consistency"
    ]

    init(profile: UserProfile, settings: UserSettings = UserSettings()) {
        self.profile = profile
        self.settings = settings
        self.selectedGoals = profile.goals
        self.nameText = profile.name ?? ""
        if let w = profile.weight { self.weightText = String(Int(w)) }
        if let ft = profile.heightFeet { self.heightFeetText = "\(ft)" }
        if let inches = profile.heightInches { self.heightInchesText = "\(inches)" }
    }

    var canContinue: Bool {
        switch step {
        case .complete:
            return false
        default:
            return true
        }
    }

    /// Smart water goal based on weight (weight_lbs / 2 = oz, / 8 = glasses)
    var smartWaterGlasses: Int {
        guard let weight = Double(weightText), weight > 0 else { return 8 }
        return max(6, min(12, Int(weight / 2.0 / 8.0)))
    }

    func advance() {
        guard canContinue else { return }
        switch step {
        case .welcome:
            step = .profile
        case .profile:
            saveProfileFields()
            applySmartDefaults()
            step = .goals
        case .goals:
            step = .healthKit
        case .healthKit:
            step = .complete
        case .complete:
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
        saveProfileFields()
        profile.goals = selectedGoals
        profile.onboardingCompleted = true
        step = .complete
    }

    private func saveProfileFields() {
        profile.name = nameText.isEmpty ? nil : nameText
        profile.weight = Double(weightText)
        profile.heightFeet = Int(heightFeetText)
        profile.heightInches = Int(heightInchesText)
    }

    private func applySmartDefaults() {
        settings.waterGoalGlasses = smartWaterGlasses
        settings.stepGoal = 8000
        settings.sleepGoalHours = 8.0
    }
}
