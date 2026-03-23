import Foundation
import SwiftData

enum WaterUnit: String, Codable, CaseIterable {
    case glasses = "Glasses"
    case ounces = "Oz"
    case liters = "L"

    var label: String { rawValue }

    /// Converts amount to glasses for goal comparison
    func toGlasses(_ amount: Double) -> Double {
        switch self {
        case .glasses: return amount
        case .ounces: return amount / 8.0  // 8 oz per glass
        case .liters: return amount / 0.237 // ~237 ml per glass
        }
    }

    var defaultPreset: Double {
        switch self {
        case .glasses: return 1.0
        case .ounces: return 8.0
        case .liters: return 0.25
        }
    }
}

@Model
final class WaterLog {
    @Attribute(.unique) var id: UUID
    var timestamp: Date
    var amount: Double
    var unit: WaterUnit
    @Relationship var dailyLog: DailyLog?

    init(
        id: UUID = UUID(),
        timestamp: Date = Date(),
        amount: Double,
        unit: WaterUnit,
        dailyLog: DailyLog? = nil
    ) {
        self.id = id
        self.timestamp = timestamp
        self.amount = amount
        self.unit = unit
        self.dailyLog = dailyLog
    }
}
