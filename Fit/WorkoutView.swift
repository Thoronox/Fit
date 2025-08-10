import SwiftUI
import SwiftData


struct WorkoutView: View {
    @Query(sort: \Workout.date, order: .reverse) private var workouts: [Workout]
    @Query private var exercises: [Exercise]
    @State private var startWorkout: Bool = false
    @State private var selectedWorkoutExercise: WorkoutExercise?
    @State private var currentWorkout: Workout?
    
    // Move delete alert state to parent view
    @State private var exerciseToDelete: WorkoutExercise?
    @State private var showDeleteAlert = false

    @StateObject private var workoutGenerator = GeminiWorkoutGeneratorService()

    var body: some View {
        VStack {
            WorkoutCriteriaView()
            if let workout = currentWorkout {
                List {
                    ForEach(workout.exercises.sorted(by: { $0.order < $1.order })) { workoutExercise in
                        ExerciseView(
                            workoutExercise: workoutExercise,
                            action: {
                                selectedWorkoutExercise = workoutExercise
                            },
                            onExerciseReplaced: { newExercise in
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
            } else {
                ProgressView("Loading workout...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }

            Button("Start Workout") {
                startWorkout = true
            }
            .buttonStyle(.borderedProminent)
            .padding(.bottom)
        }
        .navigationTitle("Workout")
        .onAppear() {
            if currentWorkout == nil {
//                currentWorkout = computeNewWorkout()
                Task {
                    await workoutGenerator.generateWorkout(
                        duration: "45m",
                        trainingType: "Hypertrophy",
                        difficulty: "Intermediate",
                        equipment: "Dumbbells"                )
                    currentWorkout = workoutGenerator.generatedWorkout
                }
            }
        }
        .sheet(isPresented: $startWorkout) {
            if let workout = currentWorkout {
                StartWorkoutView(workout: workout)
            }
        }
        // Move the delete alert to the parent view
        .alert("Delete Exercise", isPresented: $showDeleteAlert) {
            Button("Cancel", role: .cancel) {
                exerciseToDelete = nil
            }
            Button("Delete", role: .destructive) {
                if let workoutExercise = exerciseToDelete,
                   let workout = currentWorkout {
                    deleteExercise(workoutExercise, from: workout)
                }
                exerciseToDelete = nil
            }
        } message: {
            Text("Are you sure you want to delete \(exerciseToDelete?.exercise?.name ?? "this exercise")? This action cannot be undone.")
        }
    }

    private func computeNewWorkout() -> Workout {
        let newWorkout = Workout(name: "Workout \(workouts.count + 1)")
        
        for (index, exercise) in exercises.prefix(4).enumerated() {
            let workoutExercise = WorkoutExercise(exercise: exercise, order: index)
            newWorkout.exercises.append(workoutExercise)
            
            for setNumber in 1...3 {
                let set = ExerciseSet(setNumber: setNumber, weight: 50.0, reps: 10)
                workoutExercise.sets.append(set)
            }
        }
        return newWorkout
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



