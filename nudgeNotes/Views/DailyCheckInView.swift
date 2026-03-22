import SwiftUI
import SwiftData

struct DailyCheckInView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel: DailyCheckInViewModel

    init(date: Date) {
        _viewModel = State(initialValue: DailyCheckInViewModel(date: date))
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Sleep") {
                    TextField("Hours", text: $viewModel.sleepHoursText)
                        .keyboardType(.decimalPad)
                        .accessibilityIdentifier("sleep-hours-field")
                    VStack(alignment: .leading) {
                        Text("Sleep quality")
                        Slider(value: Binding(
                            get: { Double(viewModel.sleepQuality) },
                            set: { viewModel.sleepQuality = Int($0.rounded()) }
                        ), in: 1...5, step: 1)
                    }
                }

                Section("Daily signals") {
                    Toggle("Movement", isOn: $viewModel.movement)
                        .accessibilityIdentifier("movement-toggle")
                    TextField("Steps", text: $viewModel.stepsText)
                        .keyboardType(.numberPad)
                        .accessibilityIdentifier("steps-field")
                    TextField("Water glasses", text: $viewModel.waterGlassesText)
                        .keyboardType(.numberPad)
                        .accessibilityIdentifier("water-field")
                    TextField("Fasting window", text: $viewModel.fastingWindowText)
                        .keyboardType(.numberPad)
                    VStack(alignment: .leading) {
                        Text("Nutrition quality")
                        Slider(value: Binding(
                            get: { Double(viewModel.nutritionQuality) },
                            set: { viewModel.nutritionQuality = Int($0.rounded()) }
                        ), in: 1...5, step: 1)
                    }
                    VStack(alignment: .leading) {
                        Text("Mood")
                        Slider(value: Binding(
                            get: { Double(viewModel.mood) },
                            set: { viewModel.mood = Int($0.rounded()) }
                        ), in: 1...5, step: 1)
                    }
                    VStack(alignment: .leading) {
                        Text("Stress")
                        Slider(value: Binding(
                            get: { Double(viewModel.stress) },
                            set: { viewModel.stress = Int($0.rounded()) }
                        ), in: 1...5, step: 1)
                    }
                }

                Section("Notes") {
                    TextField("Notes", text: $viewModel.notes, axis: .vertical)
                        .lineLimit(4...8)
                        .accessibilityIdentifier("notes-field")
                }

                Section("Photos") {
                    if ProcessInfo.processInfo.arguments.contains("-ui-testing-use-sample-photo") {
                        Button("Add sample photo") {
                            viewModel.addPhoto(
                                data: Data([0x00, 0x01, 0x02]),
                                category: .meal,
                                notes: "Sample"
                            )
                        }
                        .accessibilityIdentifier("add-sample-photo-button")
                    }

                    Text("\(viewModel.photos.count) attached")
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Daily Check-In")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        do {
                            try viewModel.save(in: modelContext)
                            dismiss()
                        } catch {
                        }
                    }
                    .accessibilityIdentifier("save-check-in-button")
                }
            }
        }
    }
}
