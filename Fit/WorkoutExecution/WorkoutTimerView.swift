import SwiftUI

struct WorkoutTimerView: View {
    @State private var startDate = Date()

    var body: some View {
        // Updates every 0.1s so timer is smooth; blinking derived from whole seconds.
        TimelineView(.periodic(from: .now, by: 0.1)) { context in
            let elapsed = context.date.timeIntervalSince(startDate)
            let totalSeconds = Int(elapsed)
            let hours = totalSeconds / 3600
            let minutes = totalSeconds / 60
            let seconds = totalSeconds % 60
            let formatted = String(format: "%01d:%02d:%02d", hours, minutes, seconds)
            let isSelected = (totalSeconds % 2) == 0 // toggles every full second

            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .stroke(lineWidth: 2)
                        .frame(width: 24, height: 24)
                        .foregroundStyle(Color.appPrimary)
                    if isSelected {
                        Circle()
                            .frame(width: 12, height: 12)
                            .transition(.scale)
                            .foregroundStyle(Color.appPrimary)
                    }
                }
                .animation(.easeInOut(duration: 0.2), value: isSelected)

                Text(formatted)
                    .font(.system(size: 28, weight: .bold, design: .monospaced))
            }
            .padding()
        }
        .onAppear {
            startDate = Date() // reset when view appears
        }
//        .background(Color.black) // optional styling
    }
}



