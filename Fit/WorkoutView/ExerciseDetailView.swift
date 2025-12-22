import SwiftUI
import SwiftData

struct ExerciseDetailView: View {
    @Environment(\.modelContext) private var modelContext
    let workoutExercise: WorkoutExercise
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                exerciseHeader
                exerciseInfoSection
            }
            .padding()
        }
        .background(Color.black)
        .navigationTitle("Exercise Details")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    // MARK: - Header Section
    
    private var exerciseHeader: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "figure.strengthtraining.traditional")
                    .font(.largeTitle)
                    .foregroundColor(.red)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(workoutExercise.exercise?.name ?? "Unknown Exercise")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    if let equipment = workoutExercise.exercise?.equipment {
                        Text(equipment.rawValue)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            Divider()
                .background(Color.gray)
        }
    }
    
    // MARK: - Exercise Info Section
    
    private var exerciseInfoSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Exercise Information")
                .font(.headline)
                .foregroundColor(.red)
            
            if let exercise = workoutExercise.exercise {
                VStack(alignment: .leading, spacing: 12) {
                    infoRow(label: "Type", value: exercise.exerciseType.rawValue)
                    infoRow(label: "Primary Muscle", value: exercise.primaryMuscleGroup.rawValue)
                    
                    if !exercise.secondaryMuscleGroups.isEmpty {
                        infoRow(label: "Secondary Muscles", value: exercise.secondaryMuscleGroups.map { $0.rawValue }.joined(separator: ", "))
                    }
                    
                    infoRow(label: "Compound Movement", value: exercise.isCompound ? "Yes" : "No")
                    
                    if let instructions = exercise.instructions, !instructions.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Instructions")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(.secondary)
                            
                            Text(instructions)
                                .font(.body)
                                .foregroundColor(.primary)
                        }
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(8)
                    }
                }
            }
        }
    }
    
    private func infoRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.primary)
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(8)
    }
}
