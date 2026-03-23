import SwiftData
import XCTest
@testable import nudgeNotes

final class DailyCheckInViewModelTests: XCTestCase {
    func testAddAndDeleteMealDrafts() {
        let viewModel = DailyCheckInViewModel(date: WHRTestData.referenceDate)

        viewModel.addNewMeal()
        viewModel.addNewMeal()
        XCTAssertEqual(viewModel.meals.count, 2)

        viewModel.deleteMeal(at: IndexSet(integer: 0))
        XCTAssertEqual(viewModel.meals.count, 1)
    }

    func testEditModePopulatesFieldsFromExistingLog() {
        let breakfast = MealLog(
            timestamp: WHRTestData.referenceDate.addingTimeInterval(8 * 3_600),
            mealType: .breakfast,
            calories: 350
        )
        let existingLog = DailyLog(
            date: WHRTestData.referenceDate,
            sleepHours: 7.5,
            sleepQuality: 4,
            movement: true,
            steps: 8200,
            waterGlasses: 6,
            nutritionQuality: 5,
            mood: 4,
            stress: 2,
            notes: "Felt steady",
            photos: [],
            meals: [breakfast]
        )

        let viewModel = DailyCheckInViewModel(date: WHRTestData.referenceDate, existingLog: existingLog)

        XCTAssertTrue(viewModel.isEditMode)
        XCTAssertEqual(viewModel.sleepHoursText, "7.5")
        XCTAssertEqual(viewModel.stepsText, "8200")
        XCTAssertEqual(viewModel.waterGlassesText, "6")
        XCTAssertTrue(viewModel.movement)
        XCTAssertEqual(viewModel.notes, "Felt steady")
        XCTAssertEqual(viewModel.meals.count, 1)
        XCTAssertTrue(viewModel.meals.first === breakfast)
    }

    func testCalculateFastingWindowUsesPreviousDayLastMeal() throws {
        let container = PersistenceController.makeContainer(inMemory: true)
        let context = ModelContext(container)
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: WHRTestData.referenceDate)
        let yesterday = calendar.date(byAdding: .day, value: -1, to: today)!

        let previousMeal = MealLog(timestamp: yesterday.addingTimeInterval(20 * 3_600), mealType: .dinner)
        let currentMeal = MealLog(timestamp: today.addingTimeInterval(9 * 3_600), mealType: .breakfast)

        context.insert(DailyLog(date: yesterday, photos: [], meals: [previousMeal]))
        context.insert(DailyLog(date: today, photos: [], meals: [currentMeal]))
        try context.save()

        let todayLog = try context.fetch(FetchDescriptor<DailyLog>()).first(where: {
            calendar.isDate($0.date, inSameDayAs: today)
        })
        XCTAssertNotNil(todayLog)

        let viewModel = DailyCheckInViewModel(date: today, existingLog: todayLog)
        let fastingInterval = viewModel.calculateFastingWindow(modelContext: context)

        XCTAssertNotNil(fastingInterval)
        XCTAssertEqual(fastingInterval ?? 0, 13 * 3_600, accuracy: 1)
        XCTAssertEqual(viewModel.fastingWindowHours(modelContext: context) ?? 0, 13, accuracy: 0.001)
    }

    func testSaveCreatesNewLogAndUpdateMutatesExistingLog() throws {
        let container = PersistenceController.makeContainer(inMemory: true)
        let context = ModelContext(container)

        let createViewModel = DailyCheckInViewModel(date: WHRTestData.referenceDate)
        createViewModel.sleepHoursText = "8"
        createViewModel.notes = "Created"
        createViewModel.addNewMeal()
        createViewModel.meals[0].mealType = .lunch
        createViewModel.meals[0].timestamp = WHRTestData.referenceDate.addingTimeInterval(12 * 3_600)

        let created = try createViewModel.save(in: context)

        XCTAssertEqual(created.sleepHours, 8)
        XCTAssertEqual(created.meals.count, 1)

        let updateViewModel = DailyCheckInViewModel(date: WHRTestData.referenceDate, existingLog: created)
        updateViewModel.sleepHoursText = "6.5"
        updateViewModel.notes = "Updated"
        updateViewModel.deleteMeal(at: IndexSet(integer: 0))
        updateViewModel.addNewMeal()
        updateViewModel.meals[0].mealType = .dinner

        let updated = try updateViewModel.save(in: context)

        XCTAssertTrue(updated === created)
        XCTAssertEqual(updated.sleepHours, 6.5)
        XCTAssertEqual(updated.notes, "Updated")
        XCTAssertEqual(updated.meals.count, 1)
        XCTAssertEqual(updated.meals.first?.mealType, .dinner)
    }
}
