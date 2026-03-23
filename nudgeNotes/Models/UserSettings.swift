import Foundation
import Observation

enum SegmentType: String, Codable, CaseIterable, Identifiable {
    case body = "body"
    case hydration = "hydration"
    case nutrition = "nutrition"
    case movement = "movement"
    case mood = "mood"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .body: return "Body Metrics"
        case .hydration: return "Hydration"
        case .nutrition: return "Nutrition"
        case .movement: return "Movement"
        case .mood: return "Mood & Energy"
        }
    }
}

/// App-wide user settings stored in UserDefaults
@Observable
final class UserSettings {
    // Goals
    var waterGoalGlasses: Int {
        didSet { UserDefaults.standard.set(waterGoalGlasses, forKey: "waterGoalGlasses") }
    }
    var stepGoal: Int {
        didSet { UserDefaults.standard.set(stepGoal, forKey: "stepGoal") }
    }

    // Preferences
    var waterUnit: WaterUnit {
        didSet { UserDefaults.standard.set(waterUnit.rawValue, forKey: "waterUnit") }
    }
    var waterQuickPreset: Double {
        didSet { UserDefaults.standard.set(waterQuickPreset, forKey: "waterQuickPreset") }
    }
    var stepQuickPreset: Int {
        didSet { UserDefaults.standard.set(stepQuickPreset, forKey: "stepQuickPreset") }
    }

    // Segment order
    var segmentOrder: [SegmentType] {
        didSet {
            let encoded = segmentOrder.map(\.rawValue)
            UserDefaults.standard.set(encoded, forKey: "segmentOrder")
        }
    }

    // Custom workout types
    var customWorkoutTypes: [String] {
        didSet { UserDefaults.standard.set(customWorkoutTypes, forKey: "customWorkoutTypes") }
    }

    init() {
        let defaults = UserDefaults.standard
        waterGoalGlasses = defaults.object(forKey: "waterGoalGlasses") as? Int ?? 8
        stepGoal = defaults.object(forKey: "stepGoal") as? Int ?? 10_000
        waterUnit = WaterUnit(rawValue: defaults.string(forKey: "waterUnit") ?? "") ?? .glasses
        waterQuickPreset = defaults.object(forKey: "waterQuickPreset") as? Double ?? 1.0
        stepQuickPreset = defaults.object(forKey: "stepQuickPreset") as? Int ?? 500
        customWorkoutTypes = defaults.stringArray(forKey: "customWorkoutTypes") ?? []

        if let raw = defaults.stringArray(forKey: "segmentOrder") {
            segmentOrder = raw.compactMap(SegmentType.init(rawValue:))
        } else {
            segmentOrder = [.body, .hydration, .nutrition, .movement, .mood]
        }
    }

    /// All workout type names (predefined + custom)
    var allWorkoutTypes: [String] {
        PredefinedWorkoutType.allCases.map(\.rawValue) + customWorkoutTypes
    }
}
