import SwiftUI
import SwiftData

import SwiftUI
import SwiftData

struct ExerciseSelectionView: View {
    @Query private var exercises: [Exercise]
    @State private var searchText = ""
    @State private var selectedMuscleGroup: MuscleGroup?
    @State private var selectedExerciseType: ExerciseType?
    
    // Add binding to return selected exercise
    @Binding var selectedExercise: Exercise?
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            VStack {
                // Search and Filter Section
                VStack(spacing: 12) {
                    // Search Bar
                    SearchBar(text: $searchText)
                    
                    // Filter Pills
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            FilterPill(
                                title: "All Muscle Groups",
                                isSelected: selectedMuscleGroup == nil,
                                action: { selectedMuscleGroup = nil }
                            )
                            
                            ForEach(MuscleGroup.allCases, id: \.self) { muscleGroup in
                                FilterPill(
                                    title: muscleGroup.rawValue,
                                    isSelected: selectedMuscleGroup == muscleGroup,
                                    action: { selectedMuscleGroup = muscleGroup }
                                )
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                .padding(.top, 8)
                
                // Exercise List
                List {
                    ForEach(filteredExercises, id: \.id) { exercise in
                        ExerciseRowView(exercise: exercise)
                            .contentShape(Rectangle()) // Make entire row tappable
                            .onTapGesture {
                                selectedExercise = exercise
                                dismiss()
                            }
                    }
                }
                .listStyle(.plain)
            }
            .navigationTitle("Select Exercise")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private var filteredExercises: [Exercise] {
        exercises.filter { exercise in
            let matchesSearch = searchText.isEmpty ||
                exercise.name.localizedCaseInsensitiveContains(searchText)
            
            let matchesMuscleGroup = selectedMuscleGroup == nil ||
                exercise.primaryMuscleGroup == selectedMuscleGroup ||
                exercise.secondaryMuscleGroups.contains(selectedMuscleGroup!)
            
            let matchesExerciseType = selectedExerciseType == nil ||
                exercise.exerciseType == selectedExerciseType
            
            return matchesSearch && matchesMuscleGroup && matchesExerciseType
        }
    }
}



struct ExerciseRowView: View {
    let exercise: Exercise
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(exercise.name)
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Text(exercise.primaryMuscleGroup.rawValue)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    ExerciseTypeBadge(type: exercise.exerciseType)
                    
                    if exercise.isCompound {
                        CompoundBadge()
                    }
                }
            }
            
            if !exercise.secondaryMuscleGroups.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        Text("Secondary:")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        ForEach(exercise.secondaryMuscleGroups, id: \.self) { muscleGroup in
                            Text(muscleGroup.rawValue)
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.blue.opacity(0.1))
                                .foregroundColor(.blue)
                                .cornerRadius(8)
                        }
                    }
                }
            }
            
            if let equipment = exercise.equipment, equipment != .none {
                HStack {
                    Image(systemName: "dumbbell.fill")
                        .foregroundColor(.red)
                        .font(.caption)
                    
                    Text(equipment.rawValue)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            if let instructions = exercise.instructions, !instructions.isEmpty {
                Text(instructions)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
        }
        .padding(.vertical, 4)
    }
}

struct SearchBar: View {
    @Binding var text: String
    
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
            
            TextField("Search exercises...", text: $text)
                .textFieldStyle(.plain)
            
            if !text.isEmpty {
                Button("Clear") {
                    text = ""
                }
                .font(.caption)
                .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color(.systemGray6))
        .cornerRadius(10)
        .padding(.horizontal)
    }
}

struct FilterPill: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.caption)
                .fontWeight(isSelected ? .semibold : .regular)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(isSelected ? Color.red : Color(.systemGray5))
                .foregroundColor(isSelected ? .white : .primary)
                .cornerRadius(16)
        }
        .buttonStyle(.plain)
        .foregroundColor(Color.red)
    }
}

struct ExerciseTypeBadge: View {
    let type: ExerciseType
    
    var body: some View {
        Text(type.rawValue)
            .font(.caption2)
            .fontWeight(.medium)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(backgroundColor)
            .foregroundColor(.white)
            .cornerRadius(4)
    }
    
    private var backgroundColor: Color {
        switch type {
        case .strength:
            return .red
        case .cardio:
            return .green
        case .flexibility:
            return .purple
        case .plyometric:
            return .orange
        case .powerlifting:
            return .black
        case .olympic:
            return .blue
        }
    }
}

struct CompoundBadge: View {
    var body: some View {
        Text("COMPOUND")
            .font(.caption2)
            .fontWeight(.bold)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(Color.appPrimaryBackground)
            .foregroundColor(.white)
            .cornerRadius(4)
    }
}

