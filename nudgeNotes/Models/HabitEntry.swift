import Foundation

final class HabitEntry {
    var id: UUID
    var name: String
    var type: HabitType
    var value: Double?
    var completed: Bool
    var date: Date

    init(
        id: UUID = UUID(),
        name: String,
        type: HabitType,
        value: Double? = nil,
        completed: Bool = false,
        date: Date
    ) {
        self.id = id
        self.name = name
        self.type = type
        self.value = value
        self.completed = completed
        self.date = date
    }
}
