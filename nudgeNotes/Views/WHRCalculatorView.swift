import SwiftUI
import SwiftData

struct WHRCalculatorView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel: WHRCalculatorViewModel

    init(date: Date) {
        _viewModel = State(initialValue: WHRCalculatorViewModel(date: date))
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Measurements") {
                    TextField("Waist (cm)", text: $viewModel.waistText)
                        .keyboardType(.decimalPad)
                        .accessibilityIdentifier("waist-field")
                        .accessibilityLabel("Waist in centimeters")
                    TextField("Hip (cm)", text: $viewModel.hipText)
                        .keyboardType(.decimalPad)
                        .accessibilityIdentifier("hip-field")
                        .accessibilityLabel("Hip in centimeters")
                }

                Section("Result") {
                    HStack {
                        Text("Ratio")
                        Spacer()
                        Text(viewModel.ratioText)
                    }
                    HStack {
                        Text("Category")
                        Spacer()
                        Text(viewModel.category?.rawValue.capitalized ?? "--")
                            .foregroundStyle(categoryColor)
                    }
                }
            }
            .navigationTitle("WHR Calculator")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        guard viewModel.ratioValue != nil else { return }
                        do {
                            try viewModel.save(in: modelContext)
                            dismiss()
                        } catch {
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(AppTheme.accent)
                    .accessibilityIdentifier("save-whr-button")
                    .accessibilityLabel("Save WHR entry")
                }
            }
        }
    }

    private var categoryColor: Color {
        switch viewModel.category {
        case .healthy:
            return .green
        case .moderate:
            return .yellow
        case .high:
            return .red
        case .none:
            return .secondary
        }
    }
}
