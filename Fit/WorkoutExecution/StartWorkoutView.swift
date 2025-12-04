import SwiftUI

struct StartWorkoutView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @State private var selectedWorkoutExercise: WorkoutExercise?
    
    let workout: Workout
    
    var body: some View {
        VStack(spacing: 0) {
            WorkoutTimerView()
                .padding(.bottom, 8)
            
            List {
                ForEach(workout.exercises.sorted(by: { $0.order < $1.order })) { workoutExercise in
                    StaticExerciseView(workoutExercise: workoutExercise)
                        .listRowInsets(EdgeInsets())
                        .listRowSeparator(.visible, edges: .bottom)
                        .alignmentGuide(.listRowSeparatorLeading) { _ in 0 }
                        .listRowBackground(Color.clear)
                        .padding()
                }
                
                Section {
                    VStack(spacing: 12) {
                        Text("Number of Exercises \(workout.exercises.count)")
                        
                        Button("Finish Workout") {
                            finishWorkout()
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets())
                    .listRowSeparator(.hidden)
                }
            }
            .listStyle(.plain)
            .listSectionSeparator(.hidden)
            .sheet(item: $selectedWorkoutExercise) { workoutExercise in
                ExerciseExecutionView(workoutExercise: workoutExercise, readonly: false)
            }
            .padding()
        }
    }
    
    private func finishWorkout() {
        workout.duration = Date().timeIntervalSince(workout.date)
        //cleanUpWorkout(workout: workout)
/*
        modelContext.insert(workout)
        try? modelContext.save()
        
        for completedSet in workout.exercises.flatMap(\.sets) {
            let service = OneRepMaxService(modelContext: modelContext)
            // Auto-update 1RM when completing a set
            service.updateOneRepMaxFromSet(completedSet)
        }
        try? modelContext.save()
 */
        NotificationCenter.default.post(name: .workoutFinished, object: nil)
        dismiss()
    }

    }
