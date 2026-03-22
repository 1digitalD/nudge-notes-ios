import Foundation
import SwiftData

enum PersistenceController {
    static let shared = makeContainer()

    static func makeContainer(inMemory: Bool = false) -> ModelContainer {
        let schema = Schema([
            WHREntry.self,
            DailyLog.self,
            HabitEntry.self,
            PhotoLog.self,
            UserProfile.self,
            MonthlyReview.self
        ])

        let configuration: ModelConfiguration
        if inMemory {
            configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        } else {
            configuration = ModelConfiguration(schema: schema, url: storeURL)
        }

        do {
            return try ModelContainer(for: schema, configurations: [configuration])
        } catch {
            guard !inMemory else {
                fatalError("Failed to create model container: \(error)")
            }

            resetPersistentStore()
            do {
                return try ModelContainer(for: schema, configurations: [configuration])
            } catch {
                fatalError("Failed to create model container: \(error)")
            }
        }
    }

    static var storeURL: URL {
        let appSupport = URL.applicationSupportDirectory
        try? FileManager.default.createDirectory(at: appSupport, withIntermediateDirectories: true)
        return appSupport.appending(path: "nudge-notes.store")
    }

    static func resetPersistentStore() {
        let fileManager = FileManager.default
        let baseURL = storeURL
        let urls = [
            baseURL,
            baseURL.deletingPathExtension().appending(path: "\(baseURL.lastPathComponent)-shm"),
            baseURL.deletingPathExtension().appending(path: "\(baseURL.lastPathComponent)-wal")
        ]

        for url in urls where fileManager.fileExists(atPath: url.path) {
            try? fileManager.removeItem(at: url)
        }
    }
}
