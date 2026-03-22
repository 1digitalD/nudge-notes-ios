import SwiftUI
import SwiftData

@main
struct NudgeNotesApp: App {
    private let container: ModelContainer

    init() {
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
