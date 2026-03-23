import Foundation
import SwiftData

enum IntensityLevel: String, Codable, CaseIterable {
    case light = "Light"
    case moderate = "Moderate"
    case intense = "Intense"
}

@Model
final class WorkoutLog {
    @Attribute(.unique) var id: UUID
    var timestamp: Date
    var workoutTypeName: String  // Stored as string to support custom types
    var duration: Int           // minutes
    var intensity: IntensityLevel
    var notes: String?
    @Relationship var dailyLog: DailyLog?

    init(
        id: UUID = UUID(),
        timestamp: Date = Date(),
        workoutTypeName: String,
        duration: Int,
        intensity: IntensityLevel = .moderate,
        notes: String? = nil,
        dailyLog: DailyLog? = nil
    ) {
        self.id = id
        self.timestamp = timestamp
        self.workoutTypeName = workoutTypeName
        self.duration = duration
        self.intensity = intensity
        self.notes = notes
        self.dailyLog = dailyLog
    }
}

/// Predefined workout types (user can also add custom ones via UserSettings)
enum PredefinedWorkoutType: String, CaseIterable {
    case yoga = "Yoga"
    case running = "Running"
    case walking = "Walking"
    case weights = "Weights"
    case cycling = "Cycling"
    case swimming = "Swimming"
    case stretching = "Stretching"
    case hiit = "HIIT"
    case pilates = "Pilates"
    case dance = "Dance"
}
