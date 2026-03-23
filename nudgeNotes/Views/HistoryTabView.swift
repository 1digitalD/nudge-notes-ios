import SwiftUI
import SwiftData

struct HistoryTabView: View {
    let profile: UserProfile

    @Environment(\.modelContext) private var modelContext
    @Query(sort: \DailyLog.date, order: .reverse) private var dailyLogs: [DailyLog]
    @Query(sort: \MonthlyReview.month, order: .reverse) private var reviews: [MonthlyReview]

    @State private var displayedMonth: Date = Calendar.current.date(
        from: Calendar.current.dateComponents([.year, .month], from: .now)) ?? .now
    @State private var selectedDay: Date?
    @State private var searchText = ""
    @State private var exportMessage: String?
    @State private var isPresentingUpgrade = false
    @State private var isShowingMonthlyReview = false
    @State private var deletionState = HistoryDeletionState()

    private var historyViewModel: HistoryViewModel {
        HistoryViewModel(dailyLogs: dailyLogs, profileIsPro: profile.isPro)
    }

    private var currentMonthReview: MonthlyReview? {
        reviews.first {
            Calendar.current.isDate($0.month, equalTo: displayedMonth, toGranularity: .month)
        }
    }

    private var loggedDaySet: Set<Date> {
        Set(dailyLogs.map { Calendar.current.startOfDay(for: $0.date) })
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: AppSpacing.sectionSpacing) {
                    calendarCard
                    if let day = selectedDay {
                        dayDetailCard(for: day)
                    }
                    historyListSection
                }
                .padding(.horizontal, AppSpacing.md)
                .padding(.top, AppSpacing.sm)
                .padding(.bottom, AppSpacing.xl)
            }
            .background(Color.appBackground)
            .navigationTitle("History")
            .searchable(text: $searchText)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    HStack(spacing: AppSpacing.sm) {
                        Button {
                            isShowingMonthlyReview = true
                        } label: {
                            Image(systemName: "calendar.badge.checkmark")
                                .foregroundColor(.appAccent)
                        }
                        if let csv = try? historyViewModel.csvExport() {
                            ShareLink(
                                item: csv,
                                subject: Text("Nudge Notes CSV Export"),
                                message: Text("Exported from Nudge Notes")
                            ) {
                                Image(systemName: "square.and.arrow.up")
                                    .foregroundColor(.appAccent)
                            }
                        } else {
                            Button {
                                exportMessage = "CSV export is available with Pro."
                                isPresentingUpgrade = true
                            } label: {
                                Image(systemName: "square.and.arrow.up")
                                    .foregroundColor(.appAccent)
                            }
                        }
                    }
                }
            }
            .sheet(isPresented: $isShowingMonthlyReview) {
                let review = currentMonthReview
                if let review {
                    MonthlyReviewView(review: review, dailyLogs: dailyLogs)
                } else {
                    Text("No monthly review for this month.")
                        .font(AppFonts.body)
                        .foregroundColor(.appTextSecondary)
                        .padding()
                }
            }
            .sheet(isPresented: $isPresentingUpgrade) {
                ProUpgradeView(profile: profile)
            }
            .alert("Delete this log?", isPresented: Binding(
                get: { deletionState.isShowingDeleteConfirmation },
                set: { if !$0 { deletionState.cancelDelete() } }
            )) {
                Button("Delete Log", role: .destructive) {
                    if let log = deletionState.logPendingDeletion {
                        modelContext.delete(log)
                        try? modelContext.save()
                    }
                    deletionState.cancelDelete()
                }
                Button("Cancel", role: .cancel) { deletionState.cancelDelete() }
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
            .task {
                guard currentMonthReview == nil else { return }
                let review = MonthlyReview(month: displayedMonth)
                modelContext.insert(review)
                try? modelContext.save()
            }
        }
    }

    // MARK: - Calendar Card
    private var calendarCard: some View {
        AppCard {
            VStack(spacing: AppSpacing.sm) {
                // Month navigation
                HStack {
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) { navigateMonth(-1) }
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(AppFonts.bodyEmphasized)
                            .foregroundColor(.appAccent)
                            .frame(width: 36, height: 36)
                    }
                    .buttonStyle(.plain)

                    Spacer()

                    Text(displayedMonth.formatted(.dateTime.month(.wide).year()))
                        .font(AppFonts.headline)
                        .foregroundColor(.appText)

                    Spacer()

                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) { navigateMonth(1) }
                    } label: {
                        Image(systemName: "chevron.right")
                            .font(AppFonts.bodyEmphasized)
                            .foregroundColor(.appAccent)
                            .frame(width: 36, height: 36)
                    }
                    .buttonStyle(.plain)
                }

                // Day-of-week headers (Sun–Sat)
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 4) {
                    ForEach(Array(["S", "M", "T", "W", "T", "F", "S"].enumerated()), id: \.offset) { _, letter in
                        Text(letter)
                            .font(AppFonts.footnote)
                            .foregroundColor(.appTextSecondary)
                            .frame(maxWidth: .infinity)
                    }
                }

                // Calendar day grid
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 4) {
                    // Leading empty cells
                    ForEach(0..<firstWeekdayOffset, id: \.self) { _ in
                        Color.clear.frame(height: 38)
                    }
                    // Day cells
                    ForEach(calendarDays, id: \.self) { day in
                        calendarDayCell(day: day)
                    }
                }
            }
        }
    }

    private func calendarDayCell(day: Date) -> some View {
        let calendar = Calendar.current
        let isLogged = loggedDaySet.contains(calendar.startOfDay(for: day))
        let isSelected = selectedDay.map { calendar.isDate($0, inSameDayAs: day) } ?? false
        let isToday = calendar.isDateInToday(day)

        return Button {
            withAnimation(.easeInOut(duration: 0.15)) {
                selectedDay = isSelected ? nil : day
            }
        } label: {
            ZStack {
                Circle()
                    .fill(
                        isSelected ? Color.appAccent :
                        isToday ? Color.appAccent.opacity(0.12) :
                        Color.clear
                    )
                    .frame(width: 34, height: 34)

                VStack(spacing: 2) {
                    Text(day.formatted(.dateTime.day()))
                        .font(AppFonts.footnote)
                        .foregroundColor(isSelected ? .white : .appText)

                    Circle()
                        .fill(isLogged ?
                              (isSelected ? Color.white : Color.appAccent) :
                              Color.clear)
                        .frame(width: 4, height: 4)
                }
            }
            .frame(height: 38)
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("calendar-day-\(Calendar.current.component(.day, from: day))")
        .accessibilityLabel("\(day.formatted(date: .abbreviated, time: .omitted))\(isLogged ? ", logged" : "")")
    }

    // MARK: - Day Detail Card
    private func dayDetailCard(for day: Date) -> some View {
        let log = dailyLogs.first { Calendar.current.isDate($0.date, inSameDayAs: day) }
        return AppCard {
            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                HStack {
                    Text(day.formatted(.dateTime.month(.wide).day().year()))
                        .font(AppFonts.headline)
                        .foregroundColor(.appText)
                    Spacer()
                    HStack(spacing: AppSpacing.sm) {
                        NavigationLink {
                            DailyCheckInView(date: day, existingLog: log)
                        } label: {
                            Text("Edit Day")
                                .font(AppFonts.captionEmphasized)
                                .foregroundColor(.appAccent)
                                .padding(.horizontal, AppSpacing.sm)
                                .padding(.vertical, AppSpacing.xs)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                                        .stroke(Color.appAccent, lineWidth: 1)
                                )
                        }
                        Button {
                            withAnimation { selectedDay = nil }
                        } label: {
                            Image(systemName: "xmark")
                                .font(AppFonts.footnote)
                                .foregroundColor(.appTextSecondary)
                        }
                        .buttonStyle(.plain)
                    }
                }

                Divider()

                if let log {
                    LazyVGrid(
                        columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())],
                        spacing: AppSpacing.sm
                    ) {
                        statCell(icon: "💧", label: "Water",
                                 value: log.waterGlasses.map { "\($0) gl" } ?? "–")
                        statCell(icon: "🏃", label: "Movement",
                                 value: log.movement == true ? "Active" : (log.movement == false ? "Rest" : "–"))
                        statCell(icon: "🍽️", label: "Meals",
                                 value: "\(log.meals.count)")
                        statCell(icon: "😊", label: "Mood",
                                 value: log.mood.map { moodLabel($0) } ?? "–")
                        statCell(icon: "📏", label: "WHR",
                                 value: whrString(log: log))
                        statCell(icon: "📝", label: "Notes",
                                 value: (log.notes?.isEmpty == false) ? "Yes" : "–")
                    }

                    if let notes = log.notes, !notes.isEmpty {
                        Text(notes)
                            .font(AppFonts.caption)
                            .foregroundColor(.appTextSecondary)
                            .padding(.top, AppSpacing.xs)
                            .lineLimit(3)
                    }
                } else {
                    Text("No data logged for this day.")
                        .font(AppFonts.caption)
                        .foregroundColor(.appTextSecondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.vertical, AppSpacing.xs)
                }
            }
        }
    }

    private func statCell(icon: String, label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 3) {
                Text(icon).font(.system(size: 12))
                Text(label)
                    .font(AppFonts.footnote)
                    .foregroundColor(.appTextSecondary)
            }
            Text(value)
                .font(AppFonts.captionEmphasized)
                .foregroundColor(.appText)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func whrString(log: DailyLog) -> String {
        guard let waist = log.waist, let hips = log.hips, hips > 0 else { return "–" }
        return String(format: "%.2f", waist / hips)
    }

    private func moodLabel(_ mood: Int) -> String {
        switch mood {
        case 1: return "😞"
        case 2: return "😕"
        case 3: return "😐"
        case 4: return "🙂"
        case 5: return "😄"
        default: return "\(mood)"
        }
    }

    // MARK: - History List
    private var historyListSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text("All Logs")
                .font(AppFonts.headline)
                .foregroundColor(.appText)
                .padding(.horizontal, AppSpacing.xs)

            let logs = historyViewModel.filteredLogs(searchText: searchText)
            if logs.isEmpty {
                AppCard {
                    Text("No logs yet. Start by checking in today!")
                        .font(AppFonts.caption)
                        .foregroundColor(.appTextSecondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.vertical, AppSpacing.sm)
                }
            } else {
                ForEach(logs, id: \.id) { log in
                    AppCard {
                        NavigationLink {
                            DailyCheckInView(date: log.date, existingLog: log)
                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: AppSpacing.xs) {
                                    Text(log.date.formatted(date: .abbreviated, time: .omitted))
                                        .font(AppFonts.bodyEmphasized)
                                        .foregroundColor(.appText)
                                    if let notes = log.notes, !notes.isEmpty {
                                        Text(notes)
                                            .font(AppFonts.caption)
                                            .foregroundColor(.appTextSecondary)
                                            .lineLimit(1)
                                    } else {
                                        Text("No notes")
                                            .font(AppFonts.footnote)
                                            .foregroundColor(.appTextSecondary.opacity(0.6))
                                    }
                                }
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(AppFonts.footnote)
                                    .foregroundColor(.appTextSecondary)
                            }
                        }
                        .buttonStyle(.plain)
                    }
                    .accessibilityIdentifier("history-log-cell-\(log.date.formatted(date: .abbreviated, time: .omitted))")
                    .contextMenu {
                        Button(role: .destructive) {
                            deletionState.confirmDelete(for: log)
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                }
            }
        }
    }

    // MARK: - Calendar Helpers
    private var calendarDays: [Date] {
        let calendar = Calendar.current
        guard let interval = calendar.dateInterval(of: .month, for: displayedMonth) else { return [] }
        var days: [Date] = []
        var current = interval.start
        while current < interval.end {
            days.append(current)
            current = calendar.date(byAdding: .day, value: 1, to: current) ?? interval.end
        }
        return days
    }

    private var firstWeekdayOffset: Int {
        var cal = Calendar(identifier: .gregorian)
        cal.firstWeekday = 1 // Sunday
        let weekday = cal.component(.weekday, from: displayedMonth)
        return max(weekday - 1, 0)
    }

    private func navigateMonth(_ offset: Int) {
        guard let newMonth = Calendar.current.date(byAdding: .month, value: offset, to: displayedMonth) else { return }
        displayedMonth = newMonth
        selectedDay = nil
        // Ensure a review exists for the new month
        let alreadyExists = reviews.contains {
            Calendar.current.isDate($0.month, equalTo: newMonth, toGranularity: .month)
        }
        if !alreadyExists {
            let review = MonthlyReview(month: newMonth)
            modelContext.insert(review)
            try? modelContext.save()
        }
    }
}
