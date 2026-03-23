import SwiftUI
import SwiftData

struct DailyCheckInView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    let date: Date
    let existingLog: DailyLog?

    // Settings (shared across app)
    @State private var settings = UserSettings()

    // Segment expand/collapse state (all collapsed by default)
    @State private var expanded: [SegmentType: Bool] = [:]

    // Auto-save state
    @State private var saveTask: Task<Void, Never>?
    @State private var savedIndicator = false

    // The working daily log
    @State private var dailyLog: DailyLog?

    init(date: Date, existingLog: DailyLog? = nil) {
        self.date = date
        self.existingLog = existingLog
    }

    var body: some View {
        NavigationStack {
            Group {
                if let log = dailyLog {
                    ScrollView {
                        LazyVStack(spacing: 1) {
                            ForEach(settings.segmentOrder) { segment in
                                segmentView(for: segment, log: log)
                            }

                            // Notes at bottom
                            notesSegment(log: log)
                        }
                        .padding(.top, 1)
                    }
                    .background(AppTheme.background)
                } else {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .navigationTitle(navigationTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close") { dismiss() }
                        .foregroundStyle(.secondary)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    if savedIndicator {
                        HStack(spacing: 4) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(Color(hex: "#4CAF50"))
                            Text("Saved")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .transition(.opacity)
                    }
                }
            }
        }
        .onAppear { loadOrCreateLog() }
    }

    // MARK: - Segment Rendering

    @ViewBuilder
    private func segmentView(for segment: SegmentType, log: DailyLog) -> some View {
        let isExpanded = Binding(
            get: { expanded[segment] ?? false },
            set: { expanded[segment] = $0 }
        )

        switch segment {
        case .body:
            CollapsibleSegment(
                title: "Body Metrics",
                isExpanded: isExpanded,
                header: { BodyMetricsCollapsedSummary(dailyLog: log) },
                content: {
                    BodyMetricsSegmentView(dailyLog: log, onChanged: scheduleAutoSave)
                }
            )

        case .hydration:
            CollapsibleSegment(
                title: "Hydration",
                isExpanded: isExpanded,
                header: { HydrationCollapsedSummary(dailyLog: log, settings: settings) },
                content: {
                    HydrationSegmentView(
                        dailyLog: log,
                        settings: settings,
                        onChanged: scheduleAutoSave
                    )
                }
            )

        case .nutrition:
            CollapsibleSegment(
                title: "Nutrition",
                isExpanded: isExpanded,
                header: { NutritionCollapsedSummary(dailyLog: log) },
                content: {
                    NutritionSegmentView(dailyLog: log, onChanged: scheduleAutoSave)
                }
            )

        case .movement:
            CollapsibleSegment(
                title: "Movement",
                isExpanded: isExpanded,
                header: { MovementCollapsedSummary(dailyLog: log, settings: settings) },
                content: {
                    MovementSegmentView(
                        dailyLog: log,
                        settings: settings,
                        onChanged: scheduleAutoSave
                    )
                }
            )

        case .mood:
            CollapsibleSegment(
                title: "Mood & Energy",
                isExpanded: isExpanded,
                header: { MoodCollapsedSummary(dailyLog: log) },
                content: {
                    MoodSegmentView(dailyLog: log, onChanged: scheduleAutoSave)
                }
            )
        }
    }

    @ViewBuilder
    private func notesSegment(log: DailyLog) -> some View {
        let isExpanded = Binding(
            get: { expanded[.mood] ?? false }, // reuse a slot; notes isn't in SegmentType
            set: { _ in }
        )
        // Simple notes section outside of segment ordering
        VStack(spacing: 0) {
            HStack {
                Text("Notes")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(AppTheme.ink)
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)

            Divider().padding(.horizontal, 16)

            TextField(
                "Any notes for today…",
                text: Binding(
                    get: { log.notes ?? "" },
                    set: { log.notes = $0.isEmpty ? nil : $0; scheduleAutoSave() }
                ),
                axis: .vertical
            )
            .lineLimit(3...8)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .font(.subheadline)
            .accessibilityIdentifier("notes-field")

            Divider().padding(.horizontal, 16)
        }
        .background(AppTheme.cardBackground)
        .padding(.top, 8)
    }

    // MARK: - Data

    private var navigationTitle: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE, MMM d"
        return formatter.string(from: date)
    }

    private func loadOrCreateLog() {
        if let existing = existingLog {
            dailyLog = existing
        } else {
            // Look for existing log for this date
            let start = Calendar.current.startOfDay(for: date)
            let end = Calendar.current.date(byAdding: .day, value: 1, to: start) ?? start
            let descriptor = FetchDescriptor<DailyLog>(
                predicate: #Predicate<DailyLog> { log in
                    log.date >= start && log.date < end
                }
            )
            if let found = try? modelContext.fetch(descriptor).first {
                dailyLog = found
            } else {
                let log = DailyLog(date: date)
                modelContext.insert(log)
                try? modelContext.save()
                dailyLog = log
            }
        }
    }

    // MARK: - Auto-Save (debounced 1 second)

    private func scheduleAutoSave() {
        saveTask?.cancel()
        saveTask = Task {
            try? await Task.sleep(nanoseconds: 1_000_000_000)
            guard !Task.isCancelled else { return }
            await persistSave()
        }
    }

    @MainActor
    private func persistSave() {
        guard let log = dailyLog else { return }
        log.updatedAt = Date()
        try? modelContext.save()
        withAnimation {
            savedIndicator = true
        }
        Task {
            try? await Task.sleep(nanoseconds: 2_000_000_000)
            withAnimation { savedIndicator = false }
        }
    }
}
