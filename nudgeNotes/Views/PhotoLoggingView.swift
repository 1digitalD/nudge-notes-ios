import SwiftUI
import SwiftData

struct PhotoLoggingView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    let date: Date

    @State private var category: PhotoCategory = .meal
    @State private var notes = ""

    var body: some View {
        NavigationStack {
            Form {
                Picker("Category", selection: $category) {
                    ForEach(PhotoCategory.allCases, id: \.self) { option in
                        Text(option.rawValue.capitalized).tag(option)
                    }
                }

                TextEditor(text: $notes)
                    .frame(minHeight: 120)
                    .accessibilityLabel("Photo notes")

                if ProcessInfo.processInfo.arguments.contains("-ui-testing-use-sample-photo") {
                    Button("Save sample photo") {
                        saveSamplePhoto()
                    }
                    .accessibilityLabel("Save sample photo")
                }
            }
            .navigationTitle("Photo Log")
        }
    }

    private func saveSamplePhoto() {
        let photo = PhotoLog(date: date, category: category, imageData: Data([0xAA, 0xBB]), notes: notes)
        let log = DailyLog(date: date, photos: [photo])
        modelContext.insert(log)
        try? modelContext.save()
        dismiss()
    }
}
