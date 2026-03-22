import Foundation

final class PhotoLog {
    var id: UUID
    var date: Date
    var category: PhotoCategory
    var imageData: Data?
    var notes: String?

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
