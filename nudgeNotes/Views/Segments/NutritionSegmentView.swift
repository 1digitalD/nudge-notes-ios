import SwiftUI

struct NutritionSegmentView: View {
    @Bindable var dailyLog: DailyLog
    var onChanged: () -> Void

    @State private var selectedMeal: MealLog?

    private var sortedMeals: [MealLog] {
        dailyLog.meals.sorted { $0.timestamp < $1.timestamp }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if sortedMeals.isEmpty {
                SegmentEmptyState(message: "Add your first meal of the day")
            } else {
                VStack(spacing: 0) {
                    ForEach(sortedMeals) { meal in
                        HStack(spacing: 10) {
                            Button {
                                selectedMeal = meal
                            } label: {
                                HStack(spacing: 10) {
                                    Text(meal.mealType.emoji)
                                        .font(.title3)
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(meal.mealType.rawValue)
                                            .font(.subheadline)
                                            .foregroundStyle(Color.appText)
                                        HStack(spacing: 4) {
                                            Text(meal.timestamp, style: .time)
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                            if let cal = meal.calories {
                                                Text("·")
                                                    .font(.caption)
                                                    .foregroundStyle(.secondary)
                                                Text("\(cal) cal")
                                                    .font(.caption)
                                                    .foregroundStyle(.secondary)
                                            }
                                            if meal.isPackaged {
                                                Text("📦")
                                                    .font(.caption)
                                            }
                                        }
                                    }
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            .buttonStyle(.plain)

                            Button {
                                withAnimation {
                                    dailyLog.meals.removeAll { $0.id == meal.id }
                                    onChanged()
                                }
                            } label: {
                                Image(systemName: "minus.circle")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            .accessibilityLabel("Remove meal")
                        }
                        .padding(.vertical, 6)

                        if meal.id != sortedMeals.last?.id {
                            Divider()
                        }
                    }
                }
                .padding(.vertical, 4)
                .padding(.horizontal, 8)
                .background(Color.appCard.opacity(0.5))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }

            Button {
                let meal = MealLog(timestamp: Date(), mealType: .breakfast, dailyLog: dailyLog)
                dailyLog.meals.append(meal)
                dailyLog.meals.sort { $0.timestamp < $1.timestamp }
                selectedMeal = meal
                onChanged()
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "plus")
                        .font(.caption.weight(.bold))
                    Text("Add Meal")
                        .font(.caption.weight(.semibold))
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Color.appAccent.opacity(0.12))
                .foregroundStyle(Color.appAccent)
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            .accessibilityIdentifier("add-meal-button")
        }
        .navigationDestination(item: $selectedMeal) { meal in
            MealDetailView(meal: meal)
        }
    }
}

// Collapsed summary
struct NutritionCollapsedSummary: View {
    let dailyLog: DailyLog

    private var sortedMeals: [MealLog] {
        dailyLog.meals.sorted { $0.timestamp < $1.timestamp }
    }

    var body: some View {
        if sortedMeals.isEmpty {
            SegmentSummaryText(text: "No meals logged")
        } else {
            HStack(spacing: 4) {
                ForEach(sortedMeals.prefix(4)) { meal in
                    Text(meal.mealType.emoji)
                        .font(.caption)
                }
                if sortedMeals.count > 4 {
                    Text("+\(sortedMeals.count - 4)")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                if let last = sortedMeals.last {
                    Text("·")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Text(last.timestamp, style: .time)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
}

// MARK: - MealType emoji extension

extension MealType {
    var emoji: String {
        switch self {
        case .breakfast: return "🍳"
        case .lunch: return "🥗"
        case .dinner: return "🍽️"
        case .snack: return "🍎"
        }
    }
}
