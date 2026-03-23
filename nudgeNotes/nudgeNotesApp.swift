import SwiftUI
import SwiftData

@main
struct NudgeNotesApp: App {
    private let container: ModelContainer

    init() {
        let defaults = UserDefaults.standard
        if !defaults.bool(forKey: "didResetForMealTrackingMigration") {
            PersistenceController.resetDatabase()
            defaults.set(true, forKey: "didResetForMealTrackingMigration")
        }
        if !defaults.bool(forKey: "didResetForSegmentRedesignMigration") {
            PersistenceController.resetDatabase()
            defaults.set(true, forKey: "didResetForSegmentRedesignMigration")
        }
        if !defaults.bool(forKey: "didResetForMonthlyReviewMigration") {
            PersistenceController.resetDatabase()
            defaults.set(true, forKey: "didResetForMonthlyReviewMigration")
        }
        if ProcessInfo.processInfo.arguments.contains("-ui-testing-reset-store") {
            PersistenceController.resetPersistentStore()
        }
        container = PersistenceController.makeContainer()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(container)
    }
}
