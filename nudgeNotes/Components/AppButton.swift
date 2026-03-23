import SwiftUI

enum AppButtonVariant {
    case primary
    case secondary
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
        Button(action: action) {
            Text(title)
                .font(AppFonts.bodyEmphasized)
                .foregroundColor(variant == .primary ? .white : .appAccent)
                .frame(maxWidth: .infinity)
                .padding(.vertical, AppSpacing.md)
                .background(
                    RoundedRectangle(cornerRadius: AppSpacing.cornerRadius, style: .continuous)
                        .fill(variant == .primary ? Color.appAccent : Color.clear)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: AppSpacing.cornerRadius, style: .continuous)
                        .stroke(variant == .secondary ? Color.appAccent : Color.clear, lineWidth: 1.5)
                )
        }
        .buttonStyle(.plain)
    }
}
