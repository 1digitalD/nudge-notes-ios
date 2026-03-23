import SwiftUI
import SwiftData

struct DailyCheckInView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel: DailyCheckInViewModel
    @State private var selectedMeal: MealLog?

    init(date: Date, existingLog: DailyLog? = nil) {
        _viewModel = State(initialValue: DailyCheckInViewModel(date: date, existingLog: existingLog))
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Sleep") {
                    TextField("Hours", text: $viewModel.sleepHoursText)
                        .keyboardType(.decimalPad)
                        .accessibilityIdentifier("sleep-hours-field")
                        .accessibilityLabel("Sleep hours")
                    VStack(alignment: .leading) {
                        Text("Sleep quality")
                        Slider(value: Binding(
                            get: { Double(viewModel.sleepQuality) },
                            set: { viewModel.sleepQuality = Int($0.rounded()) }
                        ), in: 1...5, step: 1)
                        .accessibilityValue("\(viewModel.sleepQuality) out of 5")
                    }
                }

                Section("Daily signals") {
                    Toggle("Movement", isOn: $viewModel.movement)
                        .accessibilityIdentifier("movement-toggle")
                        .accessibilityLabel("Movement completed")
                    TextField("Steps", text: $viewModel.stepsText)
                        .keyboardType(.numberPad)
                        .accessibilityIdentifier("steps-field")
                        .accessibilityLabel("Steps")
                    TextField("Water glasses", text: $viewModel.waterGlassesText)
                        .keyboardType(.numberPad)
                        .accessibilityIdentifier("water-field")
                        .accessibilityLabel("Water glasses")
                    VStack(alignment: .leading) {
                        Text("Nutrition quality")
                        Slider(value: Binding(
                            get: { Double(viewModel.nutritionQuality) },
                            set: { viewModel.nutritionQuality = Int($0.rounded()) }
                        ), in: 1...5, step: 1)
                        .accessibilityValue("\(viewModel.nutritionQuality) out of 5")
                    }
                    VStack(alignment: .leading) {
                        Text("Mood")
                        Slider(value: Binding(
                            get: { Double(viewModel.mood) },
                            set: { viewModel.mood = Int($0.rounded()) }
                        ), in: 1...5, step: 1)
                        .accessibilityValue("\(viewModel.mood) out of 5")
                    }
                    VStack(alignment: .leading) {
                        Text("Stress")
                        Slider(value: Binding(
                            get: { Double(viewModel.stress) },
                            set: { viewModel.stress = Int($0.rounded()) }
                        ), in: 1...5, step: 1)
                        .accessibilityValue("\(viewModel.stress) out of 5")
                    }
                }

                Section("Meals") {
                    ForEach(viewModel.meals) { meal in
                        NavigationLink {
                            MealDetailView(meal: meal)
                        } label: {
                            HStack(spacing: 12) {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(meal.mealType.rawValue)
                                        .font(.headline)
                                    Text(meal.timestamp, style: .time)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                                if let calories = meal.calories {
                                    Text("\(calories) cal")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                if meal.isPackaged {
                                    Text("📦")
                                }
                            }
                        }
                    }
                    .onDelete(perform: viewModel.deleteMeal)

                    Button("Add Meal") {
                        selectedMeal = viewModel.addNewMeal()
                    }
                    .buttonStyle(.bordered)
                    .tint(AppTheme.accent)
                    .accessibilityIdentifier("add-meal-button")
                }

                Section("Fasting Window") {
                    if let hours = viewModel.fastingWindowHours(modelContext: modelContext) {
                        let wholeHours = Int(hours)
                        let minutes = Int((hours - Double(wholeHours)) * 60)
                        Text("\(wholeHours)h \(minutes)m fasting")
                            .font(.title3.weight(.semibold))
                            .foregroundStyle(AppTheme.accent)
                            .accessibilityIdentifier("fasting-window-value")
                    } else {
                        Text("Log meals to see fasting window")
                            .foregroundStyle(.secondary)
                            .font(.caption)
                    }
                }

                Section("Notes") {
                    TextField("Notes", text: $viewModel.notes, axis: .vertical)
                        .lineLimit(4...8)
                        .accessibilityIdentifier("notes-field")
                        .accessibilityLabel("Notes")
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
                        .buttonStyle(.bordered)
                        .tint(AppTheme.accent)
                        .accessibilityIdentifier("add-sample-photo-button")
                    }

                    Text("\(viewModel.photos.count) attached")
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Daily Check-In")
            .navigationDestination(item: $selectedMeal) { meal in
                MealDetailView(meal: meal)
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(viewModel.isEditMode ? "Update" : "Save") {
                        do {
                            try viewModel.save(in: modelContext)
                            dismiss()
                        } catch {
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(AppTheme.accent)
                    .accessibilityIdentifier("save-check-in-button")
                    .accessibilityIdentifier(viewModel.isEditMode ? "update-check-in-button" : "save-check-in-button")
                    .accessibilityLabel("Save daily check-in")
                }
            }
        }
    }
}
