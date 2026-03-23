import SwiftUI
import SwiftData

struct MonthlyReviewView: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var review: MonthlyReview
    let summary: MonthlyHistorySummary

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Monthly Review")
                .font(.title2.weight(.semibold))

            HStack(spacing: 12) {
                summaryCard(title: "Logged days", value: "\(summary.loggedDays)")
                summaryCard(title: "Avg sleep", value: summary.averageSleepHours == 0 ? "-" : String(format: "%.1f h", summary.averageSleepHours))
                summaryCard(title: "Avg steps", value: summary.averageSteps == 0 ? "-" : "\(summary.averageSteps)")
            }

            TextField("What felt supportive this month?", text: $review.reflection, axis: .vertical)
                .textFieldStyle(.roundedBorder)
                .lineLimit(3...5)

            TextField("What stands out in the month overall?", text: $review.summary, axis: .vertical)
                .textFieldStyle(.roundedBorder)
                .lineLimit(3...5)

            TextField("What do you want to support next month?", text: $review.nextMonthFocus, axis: .vertical)
                .textFieldStyle(.roundedBorder)
                .lineLimit(2...4)

            Button("Save Review") {
                try? modelContext.save()
            }
            .buttonStyle(.borderedProminent)
            .tint(AppTheme.accent)
        }
    }

    private func summaryCard(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.headline)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(AppTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}
