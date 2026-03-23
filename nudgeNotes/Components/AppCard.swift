import SwiftUI

struct AppCard<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .padding(AppSpacing.cardPadding)
            .background(Color.appCard)
            .clipShape(RoundedRectangle(cornerRadius: AppSpacing.cornerRadius, style: .continuous))
            .shadow(color: .black.opacity(0.05), radius: 6, x: 0, y: 2)
    }
}
