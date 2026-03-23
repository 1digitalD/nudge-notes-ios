import SwiftUI

struct MoodSegmentView: View {
    @Bindable var dailyLog: DailyLog
    var onChanged: () -> Void

    @State private var showAddMood = false

    private var sortedEntries: [MoodLog] {
        dailyLog.moodLogs.sorted { $0.timestamp < $1.timestamp }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if sortedEntries.isEmpty {
                SegmentEmptyState(message: "How are you feeling?")
            } else {
                VStack(spacing: 0) {
                    ForEach(sortedEntries) { entry in
                        HStack(alignment: .top, spacing: 10) {
                            Text(entry.emoji)
                                .font(.title3)
                            VStack(alignment: .leading, spacing: 2) {
                                HStack(spacing: 4) {
                                    Text(entry.label)
                                        .font(.subheadline)
                                        .foregroundStyle(AppTheme.ink)
                                    Text("·")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                    Text(entry.timestamp, style: .time)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                if let notes = entry.notes, !notes.isEmpty {
                                    Text(notes)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                        .lineLimit(2)
                                }
                            }
                            Spacer()
                            Button {
                                withAnimation {
                                    dailyLog.moodLogs.removeAll { $0.id == entry.id }
                                    onChanged()
                                }
                            } label: {
                                Image(systemName: "minus.circle")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            .accessibilityLabel("Remove mood entry")
                        }
                        .padding(.vertical, 6)

                        if entry.id != sortedEntries.last?.id {
                            Divider()
                        }
                    }
                }
                .padding(.vertical, 4)
                .padding(.horizontal, 8)
                .background(AppTheme.paper.opacity(0.5))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }

            Button {
                showAddMood = true
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "plus")
                        .font(.caption.weight(.bold))
                    Text("Log Mood")
                        .font(.caption.weight(.semibold))
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(AppTheme.accent.opacity(0.12))
                .foregroundStyle(AppTheme.accent)
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            .accessibilityIdentifier("log-mood-button")
        }
        .sheet(isPresented: $showAddMood) {
            AddMoodSheet { moodLog in
                moodLog.dailyLog = dailyLog
                dailyLog.moodLogs.append(moodLog)
                onChanged()
            }
        }
    }
}

// MARK: - Add Mood Sheet

struct AddMoodSheet: View {
    @Environment(\.dismiss) private var dismiss
    var onAdd: (MoodLog) -> Void

    @State private var moodValue = 3
    @State private var notes = ""

    private let moodEmojis = ["😞", "😕", "😐", "😊", "😄"]
    private let moodLabels = ["Very Low", "Low", "Neutral", "Good", "Great"]

    var body: some View {
        NavigationStack {
            VStack(spacing: 32) {
                // Mood picker
                VStack(spacing: 12) {
                    Text(moodEmojis[moodValue - 1])
                        .font(.system(size: 56))
                    Text(moodLabels[moodValue - 1])
                        .font(.title3.weight(.medium))
                        .foregroundStyle(AppTheme.ink)
                }
                .padding(.top, 24)

                HStack(spacing: 0) {
                    ForEach(1...5, id: \.self) { value in
                        Button {
                            moodValue = value
                        } label: {
                            VStack(spacing: 4) {
                                Text(moodEmojis[value - 1])
                                    .font(.title2)
                                    .opacity(moodValue == value ? 1.0 : 0.35)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                            .background(moodValue == value ? AppTheme.accent.opacity(0.1) : Color.clear)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 16)

                // Notes
                VStack(alignment: .leading, spacing: 6) {
                    Text("Notes (optional)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 16)
                    TextField("What's on your mind?", text: $notes, axis: .vertical)
                        .lineLimit(2...5)
                        .padding(12)
                        .background(AppTheme.paper.opacity(0.5))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .padding(.horizontal, 16)
                }

                Spacer()
            }
            .navigationTitle("Log Mood")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Add") {
                        let entry = MoodLog(
                            mood: moodValue,
                            notes: notes.isEmpty ? nil : notes
                        )
                        onAdd(entry)
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .foregroundStyle(AppTheme.accent)
                    .accessibilityIdentifier("confirm-log-mood-button")
                }
            }
        }
    }
}

// Collapsed summary
struct MoodCollapsedSummary: View {
    let dailyLog: DailyLog

    private var sortedEntries: [MoodLog] {
        dailyLog.moodLogs.sorted { $0.timestamp < $1.timestamp }
    }

    var body: some View {
        if sortedEntries.isEmpty {
            SegmentSummaryText(text: "No entries yet")
        } else {
            HStack(spacing: 4) {
                ForEach(sortedEntries.prefix(4)) { entry in
                    Text(entry.emoji)
                        .font(.caption)
                }
                if sortedEntries.count > 4 {
                    Text("+\(sortedEntries.count - 4)")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
}
