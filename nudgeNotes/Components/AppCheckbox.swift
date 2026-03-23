import SwiftUI

struct AppCheckbox: View {
    @Binding var isChecked: Bool
    var label: String = ""

    var body: some View {
        Button {
            isChecked.toggle()
        } label: {
            HStack(spacing: AppSpacing.sm) {
                Image(systemName: isChecked ? "checkmark.square.fill" : "square")
                    .foregroundColor(isChecked ? .appAccent : .appBorder)
                    .font(.title2)
                if !label.isEmpty {
                    Text(label)
                        .font(AppFonts.body)
                        .foregroundColor(.appText)
                }
            }
        }
        .buttonStyle(.plain)
    }
}
