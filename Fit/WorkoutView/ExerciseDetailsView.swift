import SwiftUI

struct ExerciseDetailsView: View {
    let workoutExercise: WorkoutExercise
    @Environment(\.dismiss) private var dismiss
    
    private var exercise: Exercise? {
        workoutExercise.exercise
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Exercise Icon and Name
                    exerciseHeader
                    
                    // Basic Info Section
                    infoSection
                    
                    // Instructions (if available)
                    if let instructions = exercise?.instructions, !instructions.isEmpty {
                        instructionsSection(instructions)
                    }
                }
                .padding()
            }
            .navigationTitle(exercise?.name ?? "Exercise Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    // MARK: - View Components
    
    @ViewBuilder
    private var exerciseHeader: some View {
        HStack {
            Image(systemName: "figure.strengthtraining.traditional")
                .font(.system(size: 50))
                .foregroundColor(.accentColor)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(exercise?.name ?? "Unknown Exercise")
                    .font(.title2)
                    .fontWeight(.bold)
                
                HStack {
                    let completedSets = workoutExercise.sets.filter { $0.isCompleted }.count
                    let totalSets = workoutExercise.sets.count
                    
                    if completedSets == totalSets && totalSets > 0 {
                        Label("Completed", systemImage: "checkmark.circle.fill")
                            .foregroundColor(.green)
                    } else if completedSets > 0 {
                        Label("\(completedSets)/\(totalSets) Complete", systemImage: "circle.dotted")
                            .foregroundColor(.orange)
                    } else {
                        Label("Not Started", systemImage: "circle")
                            .foregroundColor(.secondary)
                    }
                }
                .font(.caption)
            }
            
            Spacer()
        }
        .padding()
        .background(Color.secondary.opacity(0.1))
        .cornerRadius(12)
    }
    
    @ViewBuilder
    private var infoSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Exercise Information")
                .font(.headline)
            
            VStack(spacing: 12) {
                InfoRow(label: "Primary Muscle", value: exercise?.primaryMuscleGroup.rawValue ?? "N/A")
                
                if let secondaryGroups = exercise?.secondaryMuscleGroups, !secondaryGroups.isEmpty {
                    InfoRow(label: "Secondary Muscles", value: secondaryGroups.map { $0.rawValue }.joined(separator: ", "))
                }
                
                InfoRow(label: "Exercise Type", value: exercise?.exerciseType.rawValue ?? "N/A")
                
                if let equipment = exercise?.equipment {
                    InfoRow(label: "Equipment", value: equipment.rawValue)
                }
                
                InfoRow(label: "Compound Movement", value: exercise?.isCompound == true ? "Yes" : "No")
                
                InfoRow(label: "Rest Time", value: "\(workoutExercise.restTime)s")
            }
        }
    }
    
    
    @ViewBuilder
    private func instructionsSection(_ instructions: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Instructions")
                .font(.headline)
            
            Text(instructions)
                .font(.body)
                .foregroundColor(.secondary)
        }
    }    
}

// MARK: - Supporting Views

struct InfoRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .fontWeight(.medium)
        }
        .padding(.vertical, 4)
    }
}

struct SetRow: View {
    let set: ExerciseSet
    
    var body: some View {
        HStack {
            // Set number
            Text("Set \(set.setNumber)")
                .fontWeight(.semibold)
                .frame(width: 60, alignment: .leading)
            
            // Weight x Reps
            Text("\(Int(set.weight)) kg × \(set.reps) reps")
                .foregroundColor(.secondary)
            
            Spacer()
            
            // Volume
            Text("\(Int(set.volume)) kg")
                .font(.caption)
                .foregroundColor(.secondary)
            
            // Completion status
            if set.isCompleted {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
            } else {
                Image(systemName: "circle")
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(set.isCompleted ? Color.green.opacity(0.1) : Color.secondary.opacity(0.05))
        .cornerRadius(8)
    }
}

// MARK: - Preview

#Preview {
    let exercise = Exercise(
        id: "A1B2C3D4-E5F6-7890-ABCD-EF1234567890",
        name: "Bench Press",
        primaryMuscleGroup: .chest,
        exerciseType: .strength
    )
    exercise.instructions = "Lie on a flat bench with your feet flat on the ground. Grip the bar with hands slightly wider than shoulder-width apart. Lower the bar to your chest in a controlled manner, then press it back up until your arms are fully extended."
    exercise.secondaryMuscleGroups = [.triceps, .shoulders]
    exercise.equipment = .barbell
    exercise.isCompound = true
    
    let workoutExercise = WorkoutExercise(exercise: exercise, order: 1)
    
    let set1 = ExerciseSet(setNumber: 1, weight: 80, reps: 10)
    set1.isCompleted = true
    let set2 = ExerciseSet(setNumber: 2, weight: 85, reps: 8)
    set2.isCompleted = true
    let set3 = ExerciseSet(setNumber: 3, weight: 90, reps: 6)
    set3.isCompleted = false
    let set4 = ExerciseSet(setNumber: 4, weight: 90, reps: 6)
    set4.isCompleted = false
    
    workoutExercise.sets = [set1, set2, set3, set4]
    
    return ExerciseDetailsView(workoutExercise: workoutExercise)
}
