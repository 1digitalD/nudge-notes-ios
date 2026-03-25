import SwiftUI
import UIKit

enum AppButtonVariant {
    case primary
    case secondary
    case glass
}

struct AppButton: View {
    let title: String
    var variant: AppButtonVariant = .primary
    let action: () -> Void

    init(_ title: String, variant: AppButtonVariant = .primary, action: @escaping () -> Void) {
        self.title = title
        self.variant = variant
        self.action = action
    }

    var body: some View {
        Button {
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()
            action()
        } label: {
            Text(title)
                .font(AppFonts.bodyEmphasized)
                .foregroundStyle(foregroundColor)
                .frame(maxWidth: .infinity)
                .padding(.vertical, AppSpacing.md)
                .background(background)
                .clipShape(RoundedRectangle(cornerRadius: AppSpacing.cornerRadius, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private var background: some View {
        switch variant {
        case .primary:
            RoundedRectangle(cornerRadius: AppSpacing.cornerRadius, style: .continuous)
                .fill(Color.appAccent)

        case .secondary:
            RoundedRectangle(cornerRadius: AppSpacing.cornerRadius, style: .continuous)
                .fill(Color.clear)
                .overlay(
                    RoundedRectangle(cornerRadius: AppSpacing.cornerRadius, style: .continuous)
                        .stroke(Color.appAccent, lineWidth: 1.5)
                )

        case .glass:
            ZStack {
                RoundedRectangle(cornerRadius: AppSpacing.cornerRadius, style: .continuous)
                    .fill(.ultraThinMaterial)
                RoundedRectangle(cornerRadius: AppSpacing.cornerRadius, style: .continuous)
                    .stroke(
                        LinearGradient(
                            colors: [Color.white.opacity(0.3), Color.clear],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            }
        }
    }

    private var foregroundColor: Color {
        switch variant {
        case .primary: return .white
        case .secondary: return .appAccent
        case .glass: return .appText
        }
    }
}
