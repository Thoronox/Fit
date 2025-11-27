import SwiftUI

struct ExercisePauseView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var startDate = Date()
    @State private var duration = 10

    let restTime: Int
    
    var body: some View {
        VStack {
            Text("Rest")
                .font(.system(size: 25))
                .padding()
            
            HStack {
                Spacer()
                
                Button(action: {
                    duration -= 10
                }) {
                    Image(systemName: "backward.circle")
                        .symbolRenderingMode(.hierarchical)
                        .foregroundStyle(.red)
                        .font(.system(size: 40))
                }
                .buttonStyle(.plain) // or .bordered, etc.
                
                Spacer()
                
                TimelineView(.periodic(from: .now, by: 0.1)) { context in
                    self.timerText(for: context.date)
                        .font(.system(size: 40))
                }
                .onAppear {
                    startDate = Date()
                    duration = restTime
                }
                
                Spacer()
                
                Button(action: {
                    duration += 10
                }) {
                    Image(systemName: "forward.circle")
                        .symbolRenderingMode(.hierarchical)
                        .foregroundStyle(Color.appPrimary)
                        .font(.system(size: 40))
                }
                .buttonStyle(.plain) // or .bordered, etc.
                
                Spacer() 
            }
            Button("Continue") {
                dismiss()
            }
            .buttonStyle(.borderedProminent)
            .padding()
            
        }
        .presentationDetents([.height(200)])

    }
    
    private func timerText(for date: Date) -> some View {
        let elapsed = date.timeIntervalSince(startDate)
        let totalSeconds = max(0, Int(Double(duration) - elapsed))
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        let formatted = String(format: "%02d:%02d", minutes, seconds)

        if totalSeconds == 0 {
            dismiss()
        }

        return Text(formatted)
            .font(.system(size: 28, weight: .bold, design: .monospaced))
    }
}
