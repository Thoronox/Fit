import SwiftUI
import SwiftData

struct WorkoutExerciseView: View {
    let workoutExercise: WorkoutExercise
    @State private var showDetailView = false
    
    var completedSets: Int {
        workoutExercise.sets.filter { $0.isCompleted }.count
    }
    
    var totalSets: Int {
        workoutExercise.sets.count
    }

    var body: some View {
        Button(action: {
            showDetailView = true
        }) {
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
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
        .sheet(isPresented: $showDetailView) {
            NavigationStack {
                ExerciseDetailView(workoutExercise: workoutExercise)
            }
        }
    }
}

struct WorkoutExerciseView_Preview: View {
    @Query var workouts: [Workout]
    
    var body: some View {
        Group {
            if let workoutExercise = workouts.first?.exercises.first {
                WorkoutExerciseView(workoutExercise: workoutExercise)
                    .preferredColorScheme(.dark)
                    .padding()
            } else {
                Text("No workout data available")
                    .preferredColorScheme(.dark)
            }
        }
    }
}

#Preview {
    WorkoutExerciseView_Preview()
        .modelContainer(PreviewData.create().container)
}
