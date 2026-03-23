import Foundation
import SwiftData

@Model
final class MoodLog {
    @Attribute(.unique) var id: UUID
    var timestamp: Date
    var mood: Int   // 1–5
    var notes: String?
    @Relationship var dailyLog: DailyLog?

    init(
        id: UUID = UUID(),
        timestamp: Date = Date(),
        mood: Int,
        notes: String? = nil,
        dailyLog: DailyLog? = nil
    ) {
        self.id = id
        self.timestamp = timestamp
        self.mood = mood
        self.notes = notes
        self.dailyLog = dailyLog
    }

    var emoji: String {
        switch mood {
        case 1: return "😞"
        case 2: return "😕"
        case 3: return "😐"
        case 4: return "😊"
        case 5: return "😄"
        default: return "😐"
        }
    }

    var label: String {
        switch mood {
        case 1: return "Very Low"
        case 2: return "Low"
        case 3: return "Neutral"
        case 4: return "Good"
        case 5: return "Great"
        default: return "Neutral"
        }
    }
}
