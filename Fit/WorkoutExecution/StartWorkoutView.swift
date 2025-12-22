import SwiftUI
import SwiftData

struct StartWorkoutView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @State private var selectedWorkoutExercise: WorkoutExercise?
    
    // Move delete alert state to parent view
    @State private var exerciseToDelete: WorkoutExercise?
    @State private var showDeleteAlert = false

    let workout: Workout
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                WorkoutTimerView()

                List {
                    ForEach(workout.exercises.sorted(by: { $0.order < $1.order })) { workoutExercise in
                        ExerciseView(
                            workoutExercise: workoutExercise,
                            action: {
                                  // Set the selected workout exercise to launch ExerciseExecutionView
                                  selectedWorkoutExercise = workoutExercise
                              },
                            onExerciseReplaced: { newExercise in
                                // Replace the exercise in your data model
                                workoutExercise.exercise = newExercise                                
                            },
                            onExerciseDeleted: {
                                // Store the exercise to delete and show alert
                                exerciseToDelete = workoutExercise
                                showDeleteAlert = true
                            }

                        )
                        .listRowBackground(Color.black)
                    }
                }
                .listStyle(.plain)

                Text("Number of Exercises \(workout.exercises.count)")
                Button("Finish Workout") {
                    finishWorkout()
                }
                .buttonStyle(.borderedProminent)
                .padding()
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .imageScale(.large)
                            .foregroundColor(.primary)
                    }
                }
            }
            .background(Color.black)
            .alert("Delete Exercise", isPresented: $showDeleteAlert) {
                Button("Cancel", role: .cancel) {
                    exerciseToDelete = nil
                }
                Button("Delete", role: .destructive) {
                    if let workoutExercise = exerciseToDelete {
                        deleteExercise(workoutExercise, from: workout)
                    }
                    exerciseToDelete = nil
                }
            } message: {
                Text("Are you sure you want to delete \(exerciseToDelete?.exercise?.name ?? "this exercise")? This action cannot be undone.")
            }

        }
        .sheet(item: $selectedWorkoutExercise) { workoutExercise in
            ExerciseExecutionView(workoutExercise: workoutExercise, readonly: false)
        }
        
    }
    
    private func finishWorkout() {
        workout.duration = Date().timeIntervalSince(workout.date)
        cleanUpWorkout(workout: workout)
        modelContext.insert(workout)
        try? modelContext.save()

        for completedSet in workout.exercises.flatMap(\.sets) {
            let service = OneRepMaxService(modelContext: modelContext)
            // Auto-update 1RM when completing a set
            service.updateOneRepMaxFromSet(completedSet)
        }
        try? modelContext.save()
        NotificationCenter.default.post(name: .workoutFinished, object: nil)
        dismiss()
    }

    private func cleanUpWorkout(workout: Workout) {
        // delete empty sets from a workout
        for workoutExercise in workout.exercises {
            let uncompletedSets = workoutExercise.sets.filter { !$0.isCompleted }
            
            // Remove from the sets array
            workoutExercise.sets.removeAll { !$0.isCompleted }
            
            // Delete from model context
            uncompletedSets.forEach { set in
                modelContext.delete(set)
            }
        }
        
        // Remove them from the workout's exercises array
        workout.exercises.removeAll { $0.sets.isEmpty }
    }
    
    private func deleteExercise(_ workoutExercise: WorkoutExercise, from workout: Workout) {
        withAnimation {
            // Remove from the workout's exercises array
            if let index = workout.exercises.firstIndex(where: { $0.id == workoutExercise.id }) {
                workout.exercises.remove(at: index)
                
                // Reorder remaining exercises
                reorderExercises(in: workout)
            }
        }
    }
    
    private func reorderExercises(in workout: Workout) {
        // Reorder the remaining exercises to maintain sequential order
        for (index, exercise) in workout.exercises.enumerated() {
            exercise.order = index
        }
    }


}

#Preview {
    let previewData = PreviewData.create()
    
    // Access the last workout (active workout) from preview data
    if let workout = previewData.workouts.last {
        StartWorkoutView(workout: workout)
            .modelContainer(previewData.container)
            .preferredColorScheme(.dark)
    } else {
        Text("No workout data available")
            .modelContainer(previewData.container)
    }
}
