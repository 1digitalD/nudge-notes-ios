import XCTest
@testable import nudgeNotes

final class UserProfileTests: XCTestCase {
    func testUserProfileDefaults() {
        let profile = UserProfile()

        XCTAssertFalse(profile.onboardingCompleted)
        XCTAssertFalse(profile.isPro)
        XCTAssertTrue(profile.goals.isEmpty)
    }

    func testUserProfileStoresGoals() {
        let profile = UserProfile(goals: ["Sleep", "Movement"])

        XCTAssertEqual(profile.goals, ["Sleep", "Movement"])
    }
}
