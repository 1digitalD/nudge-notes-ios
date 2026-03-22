import XCTest
@testable import nudgeNotes

final class OnboardingViewModelTests: XCTestCase {
    func testInitialStateStartsOnWelcomeStep() {
        let profile = UserProfile()
        let viewModel = OnboardingViewModel(profile: profile)

        XCTAssertEqual(viewModel.step, .welcome)
        XCTAssertTrue(viewModel.selectedGoals.isEmpty)
        XCTAssertTrue(viewModel.canContinue)
    }

    func testGoalSelectionIsLimitedToThreeChoices() {
        let profile = UserProfile()
        let viewModel = OnboardingViewModel(profile: profile)

        viewModel.step = .goals
        viewModel.toggleGoal("Sleep")
        viewModel.toggleGoal("Movement")
        viewModel.toggleGoal("Stress")
        viewModel.toggleGoal("Hydration")

        XCTAssertEqual(viewModel.selectedGoals, ["Sleep", "Movement", "Stress"])
        XCTAssertTrue(viewModel.canContinue)
    }

    func testCompletionPersistsGoalsToProfile() {
        let profile = UserProfile()
        let viewModel = OnboardingViewModel(profile: profile)

        viewModel.step = .goals
        viewModel.toggleGoal("Sleep")
        viewModel.toggleGoal("Movement")
        viewModel.photoPermissionStatus = .granted
        viewModel.notificationPermissionStatus = .granted

        viewModel.completeOnboarding()

        XCTAssertTrue(profile.onboardingCompleted)
        XCTAssertEqual(profile.goals, ["Sleep", "Movement"])
        XCTAssertEqual(viewModel.step, .complete)
    }
}
