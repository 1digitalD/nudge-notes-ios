import Foundation
import SwiftData

@Model
final class WeeklyMetrics {
    @Attribute(.unique) var id: UUID
    var date: Date
    var weight: Double
    var waist: Double
    var hips: Double
    var whr: Double
    var bodyPhoto: Data?
    var createdAt: Date

    init(
        id: UUID = UUID(),
        date: Date,
        weight: Double,
        waist: Double,
        hips: Double,
        whr: Double,
        bodyPhoto: Data? = nil
    ) {
        self.id = id
        self.date = date
        self.weight = weight
        self.waist = waist
        self.hips = hips
        self.whr = whr
        self.bodyPhoto = bodyPhoto
        self.createdAt = Date()
    }
}
