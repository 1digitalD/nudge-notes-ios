import SwiftUI

struct MealDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var meal: MealLog

    var body: some View {
        Form {
            Section("Meal") {
                DatePicker("Time", selection: $meal.timestamp, displayedComponents: [.date, .hourAndMinute])
                    .accessibilityIdentifier("meal-time-picker")

                Picker("Meal type", selection: $meal.mealType) {
                    ForEach(MealType.allCases, id: \.self) { type in
                        Text(type.rawValue).tag(type)
                    }
                }
                .accessibilityIdentifier("meal-type-picker")

                TextField("Calories", text: caloriesBinding)
                    .keyboardType(.numberPad)
                    .accessibilityIdentifier("meal-calories-field")

                Toggle("Packaged/Processed", isOn: $meal.isPackaged)
                    .accessibilityIdentifier("meal-packaged-toggle")
            }

            Section("Notes") {
                TextField("Notes", text: notesBinding, axis: .vertical)
                    .lineLimit(3...5)
                    .accessibilityIdentifier("meal-notes-field")
            }

            Section {
                Button("Add Photo") {
                }
                .buttonStyle(.bordered)
                .tint(AppTheme.accent)
                .disabled(true)
            } header: {
                Text("Photos")
            } footer: {
                Text("Photo picking is reserved for a follow-up pass.")
            }
        }
        .navigationTitle("Meal")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Save") {
                    meal.updatedAt = Date()
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                .tint(AppTheme.accent)
                .accessibilityIdentifier("meal-save-button")
            }
        }
    }

    private var caloriesBinding: Binding<String> {
        Binding(
            get: { meal.calories.map(String.init) ?? "" },
            set: { meal.calories = Int($0) }
        )
    }

    private var notesBinding: Binding<String> {
        Binding(
            get: { meal.notes ?? "" },
            set: { meal.notes = $0.isEmpty ? nil : $0 }
        )
    }
}
