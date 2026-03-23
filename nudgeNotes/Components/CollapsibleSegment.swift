import SwiftUI

struct CollapsibleSegment<Header: View, Content: View>: View {
    let title: String
    @Binding var isExpanded: Bool
    @ViewBuilder let header: () -> Header
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(spacing: 0) {
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    isExpanded.toggle()
                }
            } label: {
                HStack(alignment: .top, spacing: 10) {
                    Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(AppTheme.accent)
                        .frame(width: 14)
                        .padding(.top, 2)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(title)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(AppTheme.ink)

                        if !isExpanded {
                            header()
                        }
                    }
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("\(title), \(isExpanded ? "expanded" : "collapsed")")
            .accessibilityHint("Double tap to \(isExpanded ? "collapse" : "expand")")

            if isExpanded {
                VStack(alignment: .leading, spacing: 0) {
                    Divider()
                        .padding(.horizontal, 16)
                    content()
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }

            Divider()
                .padding(.horizontal, 16)
        }
        .background(AppTheme.cardBackground)
    }
}

/// Simple summary text used in collapsed segment headers
struct SegmentSummaryText: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.caption)
            .foregroundStyle(.secondary)
            .lineLimit(1)
    }
}

/// Empty state prompt with gentle message
struct SegmentEmptyState: View {
    let message: String

    var body: some View {
        Text(message)
            .font(.subheadline)
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, 4)
    }
}
