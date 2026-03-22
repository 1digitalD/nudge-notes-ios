import Foundation
import SwiftData

final class WHRCalculatorViewModel {
    let date: Date
    var waistText = ""
    var hipText = ""

    init(date: Date) {
        self.date = date
    }

    var ratioValue: Double? {
        guard let waist = Double(waistText), let hip = Double(hipText), hip > 0 else {
            return nil
        }
        return waist / hip
    }

    var ratioText: String {
        guard let ratioValue else { return "--" }
        return String(format: "%.2f", ratioValue)
    }

    var category: WHRCategory? {
        guard let ratioValue else { return nil }
        return WHREntry.calculateCategory(for: ratioValue)
    }

    @discardableResult
    func save(in context: ModelContext) throws -> WHREntry {
        let entry = WHREntry(
            date: date,
            waist: Double(waistText) ?? 0,
            hip: Double(hipText) ?? 0
        )
        context.insert(entry)
        try context.save()
        return entry
    }
}
