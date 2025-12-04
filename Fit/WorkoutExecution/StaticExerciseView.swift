import SwiftUI

struct StaticExerciseView: View {
    var workoutExercise: WorkoutExercise

    var completedSets: Int {
        workoutExercise.sets.filter { $0.isCompleted }.count
    }
    
    var totalSets: Int {
        workoutExercise.sets.count
    }

    var body: some View {
        HStack {
            Image(systemName: "figure.strengthtraining.traditional")
                .imageScale(.large)
                .foregroundColor(.primary)
                .padding(.trailing, 20)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(workoutExercise.exercise?.name ?? "Unknown Exercise")
                    .fontWeight(.bold)
                
                HStack {
                    Text("\(completedSets)/\(totalSets) sets")
                    
                    if let lastSet = workoutExercise.sets.last {
                        Text("•")
                        Text("\(lastSet.reps) reps")
                        Text("•")
                        Text("\(Int(lastSet.weight)) kg")
                    }
                    
                    Spacer()
                    
                    if completedSets == totalSets && totalSets > 0 {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                    } else if completedSets > 0 {
                        Image(systemName: "circle.dotted")
                            .foregroundColor(.orange)
                    }
                }
                .font(.caption)
                .foregroundColor(.secondary)
            }
            Spacer()
        }
    }
}

struct StaticExerciseView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            // Completed Exercise
            StaticExerciseView(workoutExercise: makeWorkoutExercise(
                name: "Bench Press",
                muscleGroup: .chest,
                allCompleted: true
            ))
            .previewDisplayName("Completed")
            
            // Partial Progress
            StaticExerciseView(workoutExercise: makeWorkoutExercise(
                name: "Squat",
                muscleGroup: .quadriceps,
                allCompleted: false,
                completedCount: 2
            ))
            .previewDisplayName("Partial Progress")
            
            // Not Started
            StaticExerciseView(workoutExercise: makeWorkoutExercise(
                name: "Deadlift",
                muscleGroup: .back,
                allCompleted: false,
                completedCount: 0
            ))
            .previewDisplayName("Not Started")
        }
        .padding()
//        .preferredColorScheme(.dark)
    }
    
    static func makeWorkoutExercise(
        name: String,
        muscleGroup: MuscleGroup,
        allCompleted: Bool,
        completedCount: Int = 4
    ) -> WorkoutExercise {
        let exercise = Exercise(
            id: UUID().uuidString,
            name: name,
            primaryMuscleGroup: muscleGroup,
            exerciseType: .strength
        )
        
        let workoutExercise = WorkoutExercise(exercise: exercise, order: 0)
        
        // Add sets
        for i in 1...4 {
            let set = ExerciseSet(
                setNumber: i,
                weight: 80.0 + (Double(i) * 2.5),
                reps: 10 - i
            )
            set.isCompleted = allCompleted ? true : (i <= completedCount)
            set.workoutExercise = workoutExercise
            workoutExercise.sets.append(set)
        }
        
        return workoutExercise
    }
}
