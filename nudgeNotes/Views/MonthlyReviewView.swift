import SwiftUI
import SwiftData

struct MonthlyReviewView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Bindable var review: MonthlyReview
    let dailyLogs: [DailyLog]

    @State private var saveTask: Task<Void, Never>?

    private var monthlyLogs: [DailyLog] {
        let calendar = Calendar.current
        guard let interval = calendar.dateInterval(of: .month, for: review.month) else { return [] }
        return dailyLogs.filter { interval.contains($0.date) }
    }

    private var daysLogged: Int { monthlyLogs.count }

    private var consistencyText: String {
        let calendar = Calendar.current
        let daysInMonth = calendar.range(of: .day, in: .month, for: review.month)?.count ?? 30
        guard daysInMonth > 0 else { return "–" }
        let pct = Int(Double(daysLogged) / Double(daysInMonth) * 100)
        return "\(pct)%"
    }

    private var whrChangeText: String {
        let sorted = monthlyLogs.sorted { $0.date < $1.date }
        let values = sorted.compactMap { log -> Double? in
            guard let waist = log.waist, let hips = log.hips, hips > 0 else { return nil }
            return waist / hips
        }
        guard values.count >= 2, let first = values.first, let last = values.last else { return "–" }
        let change = last - first
        return (change >= 0 ? "+" : "") + String(format: "%.2f", change)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: AppSpacing.sectionSpacing) {
                    statsCard
                    reflectionCard
                }
                .padding(.horizontal, AppSpacing.md)
                .padding(.top, AppSpacing.sm)
                .padding(.bottom, AppSpacing.xl)
            }
            .background(Color.appBackground)
            .navigationTitle(review.month.formatted(.dateTime.month(.wide).year()))
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .font(AppFonts.bodyEmphasized)
                        .foregroundColor(.appAccent)
                }
            }
        }
    }

    // MARK: - Stats Card
    private var statsCard: some View {
        AppCard {
            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                Text("This Month")
                    .font(AppFonts.headline)
                    .foregroundColor(.appText)

                Divider()

                HStack(spacing: 0) {
                    statItem(value: "\(daysLogged)", label: "Days Logged")
                    Divider().frame(height: 44)
                    statItem(value: consistencyText, label: "Consistency")
                    Divider().frame(height: 44)
                    statItem(value: whrChangeText, label: "WHR Change")
                }
            }
        }
    }

    private func statItem(value: String, label: String) -> some View {
        VStack(spacing: AppSpacing.xs) {
            Text(value)
                .font(AppFonts.headline)
                .foregroundColor(.appAccent)
            Text(label)
                .font(AppFonts.footnote)
                .foregroundColor(.appTextSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, AppSpacing.xs)
    }

    // MARK: - Reflection Card
    private var reflectionCard: some View {
        AppCard {
            VStack(alignment: .leading, spacing: AppSpacing.md) {
                Text("Reflection")
                    .font(AppFonts.headline)
                    .foregroundColor(.appText)

                Divider()

                promptEditor(label: "What went well?", text: $review.wentWell)
                promptEditor(label: "What was challenging?", text: $review.challenges)
                promptEditor(label: "One small change for next month:", text: $review.changeForNextMonth)
            }
        }
    }

    private func promptEditor(label: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.xs) {
            Text(label)
                .font(AppFonts.captionEmphasized)
                .foregroundColor(.appTextSecondary)
            TextEditor(text: text)
                .font(AppFonts.body)
                .foregroundColor(.appText)
                .frame(minHeight: 80)
                .padding(AppSpacing.sm)
                .background(Color.appBackground)
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .stroke(Color.appBorder, lineWidth: 1)
                )
                .onChange(of: text.wrappedValue) { _, _ in
                    scheduleAutoSave()
                }
        }
    }

    private func scheduleAutoSave() {
        saveTask?.cancel()
        saveTask = Task {
            try? await Task.sleep(nanoseconds: 1_000_000_000)
            guard !Task.isCancelled else { return }
            review.updatedAt = Date()
            try? modelContext.save()
        }
    }
}
