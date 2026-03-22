import SwiftUI

struct ContentView: View {
    var body: some View {
        NavigationStack {
            VStack(spacing: 12) {
                Text("nudge Notes")
                    .font(.largeTitle.weight(.semibold))
                Text("WHR & Habit Tracker")
                    .foregroundStyle(.secondary)
            }
            .padding()
        }
    }
}
