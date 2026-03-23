import XCTest
@testable import nudgeNotes

final class MealLogTests: XCTestCase {
    func testMealLogStoresProperties() {
        let meal = MealLog(
            timestamp: WHRTestData.referenceDate,
            mealType: .lunch,
            notes: "Chicken salad",
            calories: 540,
            isPackaged: true
        )

        XCTAssertEqual(meal.mealType, .lunch)
        XCTAssertEqual(meal.notes, "Chicken salad")
        XCTAssertEqual(meal.calories, 540)
        XCTAssertTrue(meal.isPackaged)
    }

    func testMealLogCanRelateToDailyLog() {
        let meal = MealLog(timestamp: WHRTestData.referenceDate, mealType: .breakfast)
        let log = DailyLog(date: WHRTestData.referenceDate, photos: [], meals: [meal])

        XCTAssertEqual(log.meals.count, 1)
        XCTAssertTrue(log.meals.first === meal)
        XCTAssertEqual(log.meals.first?.mealType, .breakfast)
    }

    func testMealLogCanRelateToPhotoLog() {
        let photo = PhotoLog(date: WHRTestData.referenceDate, category: .meal, imageData: Data([0x01]), notes: "Meal")
        let meal = MealLog(timestamp: WHRTestData.referenceDate, mealType: .dinner, photos: [photo])

        XCTAssertEqual(meal.photos.count, 1)
        XCTAssertTrue(meal.photos.first === photo)
        XCTAssertEqual(meal.photos.first?.category, .meal)
    }
}
