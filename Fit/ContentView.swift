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
            let ORMService = OneRepMaxService(modelContext: modelContext)
            let ORM = ORMService.getCurrentOneRepMaxByExerciseName("Push-Ups")
            print (ORM?.date)
            print (ORM?.oneRepMax)

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
    
    func clearAllData(modelContext: ModelContext) {
        do {
            // Delete all instances of each model type
            try modelContext.delete(model: OneRepMaxHistory.self)
            try modelContext.delete(model: PersonalRecord.self)
            try modelContext.delete(model: ExerciseSet.self)
            try modelContext.delete(model: WorkoutExercise.self)
            try modelContext.delete(model: Exercise.self)
            
            // Save the changes
            try modelContext.save()
            
            print("All data cleared successfully")
        } catch {
            print("Error clearing data: \(error)")
        }
    }
}



#Preview {
    ContentView()
        .modelContainer(for: Item.self, inMemory: true)
        .preferredColorScheme(.dark)
}
