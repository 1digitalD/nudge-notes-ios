import Foundation

final class WHREntry {
    var id: UUID
    var date: Date
    var waist: Double
    var hip: Double
    var ratio: Double
    var category: WHRCategory

    init(id: UUID = UUID(), date: Date, waist: Double, hip: Double) {
        self.id = id
        self.date = date
        self.waist = waist
        self.hip = hip

        let computedRatio = hip > 0 ? waist / hip : 0
        self.ratio = computedRatio
        self.category = WHREntry.calculateCategory(for: computedRatio)
    }

    func calculateCategory() -> WHRCategory {
        let nextCategory = Self.calculateCategory(for: ratio)
        category = nextCategory
        return nextCategory
    }

    func isHealthy() -> Bool {
        calculateCategory() == .healthy
    }

    static func calculateCategory(for ratio: Double) -> WHRCategory {
        if ratio < 0.8 {
            return .healthy
        }

        if ratio < 0.85 {
            return .moderate
        }

        return .high
    }
}
