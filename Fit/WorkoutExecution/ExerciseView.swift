import SwiftUI
import SwiftData

struct ExerciseView: View {
    @State private var selectedExercise: Exercise?
    @State private var replaceExercise = false

    let workoutExercise: WorkoutExercise
    let action: () -> Void
    
    let onExerciseReplaced: ((Exercise) -> Void)?
    let onExerciseDeleted: (() -> Void)? // Make sure this is not nil

    var completedSets: Int {
        workoutExercise.sets.filter { $0.isCompleted }.count
    }
    
    var totalSets: Int {
        workoutExercise.sets.count
    }

    var body: some View {
        Button(action: action) {
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
        .swipeActions(edge: .trailing) {
            Button {
                replaceExercise = true
            } label: {
                Label("Replace", systemImage: "arrow.2.squarepath")
            }
            .tint(.blue)
            
            Button(role: .destructive) {
                onExerciseDeleted?()
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
        .sheet(isPresented: $replaceExercise) {
            ExerciseSelectionView(selectedExercise: $selectedExercise)
        }
        .onChange(of: selectedExercise) { _, newExercise in
            if let newExercise = newExercise {
                onExerciseReplaced?(newExercise)
                selectedExercise = nil
            }
        }
    }
}

struct ExerciseView_Preview: View {
    @Query var workouts: [Workout]
    
    var body: some View {
        Group {
            if let workoutExercise = workouts.first?.exercises.first {
                ExerciseView(
                    workoutExercise: workoutExercise,
                    action: {},
                    onExerciseReplaced: { _ in },
                    onExerciseDeleted: {}
                )
                .preferredColorScheme(.dark)
                .padding()
            } else {
                Text("No workout data available")
            }
        }
    }
}

#Preview {
    ExerciseView_Preview()
        .modelContainer(PreviewData.create().container)
}
