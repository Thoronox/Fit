import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    
    var body: some View {
        TabView {
            NavigationStack {
                WorkoutView()
            }
            .tabItem { Label("Workout", systemImage: "figure.strengthtraining.traditional") }
            
            NavigationStack {
                LogView()
            }
            .tabItem { Label("Log", systemImage: "list.clipboard") }
        }
        .tint(.red)
        .onAppear {
            //            seedDataIfNeeded()
            loadExercises()
        }
    }
    
    private func loadExercises() {
        var errorMessage = ""
        do {
            try ExerciseLoader.loadExercisesFromJSON(context: modelContext)
            //  try ExerciseLoader.resetExercises(context: modelContext)
        } catch {
            errorMessage = error.localizedDescription
            print(errorMessage)
        }
    }
}



#Preview {
    ContentView()
        .modelContainer(for: Item.self, inMemory: true)
        .preferredColorScheme(.dark)
}
