import SwiftUI
import SwiftData

struct HistoryTabView: View {
    let profile: UserProfile

    @Environment(\.modelContext) private var modelContext
    @Query(sort: \DailyLog.date, order: .reverse) private var dailyLogs: [DailyLog]
    @Query(sort: \MonthlyReview.monthStart, order: .reverse) private var reviews: [MonthlyReview]

    @State private var searchText = ""
    @State private var selectedDay: Date?
    @State private var exportMessage: String?
    @State private var isPresentingUpgrade = false
    @State private var navigationState = HistoryNavigationState()
    @State private var deletionState = HistoryDeletionState()

    private var historyViewModel: HistoryViewModel {
        HistoryViewModel(dailyLogs: dailyLogs, profileIsPro: profile.isPro)
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    if let review = reviews.first {
                        MonthlyReviewView(review: review, summary: historyViewModel.monthlySummary(for: review.monthStart))
                    } else {
                        ProgressView()
                    }
                }

                Section("Calendar") {
                    CalendarHeatmapView(
                        heatmap: historyViewModel.heatmapByDay,
                        selectedDay: selectedDay
                    ) { day in
                        selectedDay = Calendar.current.isDate(selectedDay ?? .distantPast, inSameDayAs: day) ? nil : day
                    }
                    if let selectedDay {
                        HStack {
                            Text("Showing \(selectedDay.formatted(date: .abbreviated, time: .omitted))")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Spacer()
                            Button("Clear") {
                                self.selectedDay = nil
                            }
                            .font(.caption.weight(.semibold))
                            .buttonStyle(.bordered)
                            .tint(AppTheme.accent)
                        }
                    }
                }

                Section("History") {
                    ForEach(historyViewModel.filteredLogs(searchText: searchText, selectedDay: selectedDay), id: \.id) { log in
                        NavigationLink {
                            DailyCheckInView(date: log.date, existingLog: log)
                        } label: {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(log.date.formatted(date: .abbreviated, time: .omitted))
                                    .font(.headline)
                                if let notes = log.notes, !notes.isEmpty {
                                    Text(notes)
                                        .foregroundStyle(.secondary)
                                } else {
                                    Text("No notes yet")
                                        .foregroundStyle(.tertiary)
                                }
                            }
                        }
                        .accessibilityIdentifier("history-log-cell-\((log.notes?.isEmpty == false ? log.notes! : log.date.formatted(date: .abbreviated, time: .omitted)))")
                        .swipeActions {
                            Button(role: .destructive) {
                                deletionState.confirmDelete(for: log)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                            .accessibilityIdentifier("history-delete-button")
                        }
                    }
                }
            }
            .navigationTitle("History")
            .searchable(text: $searchText)
            .sheet(isPresented: $isPresentingUpgrade) {
                ProUpgradeView(profile: profile)
            }
            .task {
                guard reviews.isEmpty else { return }
                let review = MonthlyReview(
                    monthStart: Calendar.current.date(
                        from: Calendar.current.dateComponents([.year, .month], from: .now)
                    ) ?? .now
                )
                modelContext.insert(review)
                try? modelContext.save()
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    if let csv = try? historyViewModel.csvExport() {
                        ShareLink(
                            item: csv,
                            subject: Text("Nudge Notes CSV Export"),
                            message: Text("Exported from Nudge Notes")
                        ) {
                            Label("Export CSV", systemImage: "square.and.arrow.up")
                        }
                    } else {
                        Button("Export CSV") {
                            exportMessage = "CSV export is available with Pro."
                            isPresentingUpgrade = true
                        }
                        .buttonStyle(.bordered)
                        .tint(AppTheme.accent)
                    }
                }
            }
            .alert("Delete this log?", isPresented: Binding(
                get: { deletionState.isShowingDeleteConfirmation },
                set: { if !$0 { deletionState.cancelDelete() } }
            )) {
                Button("Delete Log", role: .destructive) {
                    if let pendingDeleteLog = deletionState.logPendingDeletion {
                        modelContext.delete(pendingDeleteLog)
                        try? modelContext.save()
                    }
                    deletionState.cancelDelete()
                }
                Button("Cancel", role: .cancel) {
                    deletionState.cancelDelete()
                }
            } message: {
                Text("This removes the selected daily log from history.")
            }
            .alert("Export", isPresented: Binding(
                get: { exportMessage != nil },
                set: { if !$0 { exportMessage = nil } }
            )) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(exportMessage ?? "")
            }
        }
    }
}

private struct CalendarHeatmapView: View {
    let heatmap: [Date: Int]
    let selectedDay: Date?
    let onSelectDay: (Date) -> Void

    var body: some View {
        let days = currentMonthDays()
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 8) {
            ForEach(days, id: \.self) { day in
                let count = heatmap[Calendar.current.startOfDay(for: day), default: 0]
                let isSelected = selectedDay.map { Calendar.current.isDate($0, inSameDayAs: day) } ?? false
                Button {
                    onSelectDay(day)
                } label: {
                    Text(day.formatted(.dateTime.day()))
                        .font(.caption)
                        .frame(maxWidth: .infinity, minHeight: 28)
                        .background(count == 0 ? Color.gray.opacity(0.12) : Color.green.opacity(min(Double(count) * 0.25, 0.9)))
                        .overlay {
                            if isSelected {
                                RoundedRectangle(cornerRadius: 8, style: .continuous)
                                    .stroke(Color.primary, lineWidth: 2)
                            }
                        }
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                }
                .buttonStyle(.bordered)
                .tint(isSelected ? AppTheme.accent : AppTheme.paper)
                .accessibilityIdentifier("heatmap-day-\(Calendar.current.component(.day, from: day))")
                .accessibilityLabel("\(day.formatted(date: .abbreviated, time: .omitted)), \(count) logs")
            }
        }
    }

    private func currentMonthDays() -> [Date] {
        let calendar = Calendar.current
        let interval = calendar.dateInterval(of: .month, for: .now) ?? DateInterval(start: .now, end: .now)
        var days: [Date] = []
        var current = interval.start
        while current < interval.end {
            days.append(current)
            current = calendar.date(byAdding: .day, value: 1, to: current) ?? interval.end
        }
        return days
    }
}
