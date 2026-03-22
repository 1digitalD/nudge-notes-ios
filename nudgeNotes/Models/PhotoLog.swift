import Foundation
import SwiftData

@Model
final class PhotoLog {
    @Attribute(.unique) var id: UUID
    var date: Date
    var category: PhotoCategory
    @Attribute(.externalStorage)
    var imageData: Data?
    var notes: String?
    var dailyLog: DailyLog?

    init(
        id: UUID = UUID(),
        date: Date,
        category: PhotoCategory,
        imageData: Data? = nil,
        notes: String? = nil
    ) {
        self.id = id
        self.date = date
        self.category = category
        self.imageData = imageData
        self.notes = notes
    }
}
