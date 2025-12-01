import SwiftUI

struct ExerciseExecutionView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @State private var currentSetIndex = 0

    @Bindable var workoutExercise: WorkoutExercise
    let readonly: Bool

    fileprivate enum Field: Hashable {
        case reps(index: Int)
        case weight(index: Int)
    }
    @FocusState private var focusedField: Field?
    @State private var showPauseTimer = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if (!readonly) {
                    WorkoutTimerView()
                }

                headerView
                setsScroll
                bottomButtons
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
        }
        .onAppear {
            setupInitialState()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                focusedField = .reps(index: currentSetIndex)
            }
        }
        .sheet(isPresented: $showPauseTimer) {
            ExercisePauseView(restTime: workoutExercise.restTime)
        }
    }

    // MARK: - Subviews

    private var headerView: some View {
        VStack(spacing: 8) {
            Text(workoutExercise.exercise?.name ?? "Unknown Exercise")
                .font(.title2)
                .fontWeight(.bold)

            if let equipment = workoutExercise.exercise?.equipment {
                Text(equipment.rawValue)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
    }

    private var setsScroll: some View {
        VStack(spacing: 0) {
            // Header Row
            HStack {
                Text("")
                    .frame(width: 10)

                VStack {
                    Text("Reps")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)

                VStack {
                    Text("Weight (kg)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
            }
            .padding(.horizontal)
            .padding(.bottom, 8)

            // Sets List - FIXED: Use the sets directly instead of indices
            List {
                ForEach(workoutExercise.sets) { set in
                    if let index = workoutExercise.sets.firstIndex(where: { $0.id == set.id }) {
                        SetRowView(
                            set: $workoutExercise.sets[index],
                            index: index,
                            focusedField: $focusedField,
                            onRepsChange: { newValue in
                                propagateRepsToBelow(fromIndex: index, value: newValue)
                            },
                            onWeightChange: { newValue in
                                propagateWeightToBelow(fromIndex: index, value: newValue)
                            }
                        )
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                        .swipeActions(edge: .trailing) {
                            Button("Delete") {
                                deleteSet(at: index)
                            }
                            .tint(.red)
                        }
                    }
                }

                // Add Set Button
                Button(action: addSet) {
                    HStack {
                        Image(systemName: "plus.circle")
                            .font(.title2)
                        Text("Add Set")
                            .font(.headline)
                    }
                    .foregroundColor(.red)
                }
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
                .padding(.vertical, 8)
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .background(Color.black)
        }
    }

    private var bottomButtons: some View {
        VStack(spacing: 12) {
            if (readonly) {
                Button("Close") {
                    dismiss()
                }
                .frame(maxWidth: .infinity, minHeight: 50)
                .background(Color.red)
                .foregroundColor(.white)
                .font(.headline)
                .cornerRadius(12)
            } else {
                Button("Log All Sets") {
                    logAllSets()
                }
                .frame(maxWidth: .infinity, minHeight: 50)
                .background(Color.gray.opacity(0.3))
                .foregroundColor(.white)
                .font(.headline)
                .cornerRadius(12)
                
                Button("Log Set & Next Exercise") {
                    logCurrentSet()
                }
                .frame(maxWidth: .infinity, minHeight: 50)
                .background(Color.appPrimary)
                .foregroundColor(.white)
                .font(.headline)
                .cornerRadius(12)
                .disabled(shouldDisableLogButton)
            }
        }
        .padding()
    }

    // MARK: - Logic
    
    private var shouldDisableLogButton: Bool {
        guard currentSetIndex < workoutExercise.sets.count else { return true }
        let currentSet = workoutExercise.sets[currentSetIndex]
        // Button is disabled if reps is 0 or weight is negative
        return currentSet.reps == 0 || currentSet.weight < 0
    }
    
    private func setupInitialState() {
        // Find the first incomplete set
        currentSetIndex = workoutExercise.sets.firstIndex { !$0.isCompleted } ?? 0
    }

    private func addSet() {
        let newSetNumber = workoutExercise.sets.count + 1
        let newSet = ExerciseSet(setNumber: newSetNumber, weight: 0, reps: 0)
        newSet.workoutExercise = workoutExercise
        workoutExercise.sets.append(newSet)
    }

    private func deleteSet(at index: Int) {
        // Don't allow deleting if there's only one set
        guard workoutExercise.sets.count > 1, index < workoutExercise.sets.count else { return }
        
        // Remove from the data model
        workoutExercise.sets.remove(at: index)
        
        // Update set numbers for remaining sets
        for (newIndex, set) in workoutExercise.sets.enumerated() {
            set.setNumber = newIndex + 1
        }
        
        // Adjust currentSetIndex if necessary
        if currentSetIndex >= workoutExercise.sets.count {
            currentSetIndex = max(0, workoutExercise.sets.count - 1)
        }
        
        // Find the next incomplete set
        if let nextIncompleteIndex = workoutExercise.sets.firstIndex(where: { !$0.isCompleted }) {
            currentSetIndex = nextIncompleteIndex
        }
    }

    // MARK: - Propagation Methods
    
    private func propagateRepsToBelow(fromIndex: Int, value: String) {
        guard fromIndex < workoutExercise.sets.count,
              let repsValue = Int(value), repsValue > 0 else { return }
        
        for index in (fromIndex + 1)..<workoutExercise.sets.count {
            if !workoutExercise.sets[index].isCompleted {
                workoutExercise.sets[index].reps = repsValue
            }
        }
    }
    
    private func propagateWeightToBelow(fromIndex: Int, value: String) {
        guard fromIndex < workoutExercise.sets.count,
              let weightValue = Double(value), weightValue >= 0 else { return }
        
        for index in (fromIndex + 1)..<workoutExercise.sets.count {
            if !workoutExercise.sets[index].isCompleted {
                workoutExercise.sets[index].weight = weightValue
            }
        }
    }

    private func logAllSets() {
        for set in workoutExercise.sets {
            set.isCompleted = true
        }
        dismiss()
    }

    private func logCurrentSet() {
        guard currentSetIndex < workoutExercise.sets.count else { return }
        let set = workoutExercise.sets[currentSetIndex]
        
        // Validate that we have valid values (allow weight of 0 for bodyweight exercises)
        guard set.reps > 0 && set.weight >= 0 else { return }
        
        set.isCompleted = true
        
        // Mark all subsequent sets as not completed so they can be re-logged
        for index in (currentSetIndex + 1)..<workoutExercise.sets.count {
            workoutExercise.sets[index].isCompleted = false
        }

        if currentSetIndex < workoutExercise.sets.count - 1 {
            currentSetIndex += 1
            focusedField = .reps(index: currentSetIndex)
            showPauseTimer = true
        } else {
            dismiss()
        }
    }
}

// MARK: - Per-row view

fileprivate struct SetRowView: View {
    @Binding var set: ExerciseSet
    let index: Int
    @FocusState.Binding var focusedField: ExerciseExecutionView.Field?
    let onRepsChange: (String) -> Void
    let onWeightChange: (String) -> Void

    var body: some View {
        HStack(spacing: 12) {
            // Set Number
            ZStack {
                Circle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 30, height: 30)

                Text(set.isCompleted ? "✓" : "\(index + 1)")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(set.isCompleted ? .green : .white)
            }

            // Reps Input
            RepsTextField(
                reps: $set.reps,
                focusedField: $focusedField,
                index: index,
                isCompleted: set.isCompleted,
                onChange: onRepsChange
            )

            // Weight Input
            WeightTextField(
                weight: $set.weight,
                focusedField: $focusedField,
                index: index,
                isCompleted: set.isCompleted,
                onChange: onWeightChange
            )
        }
    }
}

fileprivate struct RepsTextField: View {
    @Binding var reps: Int
    @FocusState.Binding var focusedField: ExerciseExecutionView.Field?
    let index: Int
    let isCompleted: Bool
    let onChange: (String) -> Void
    
    var body: some View {
        TextField("6", value: $reps, format: .number)
            .focused($focusedField, equals: .reps(index: index))
            .font(.system(size: 24, weight: .bold, design: .default))
            .multilineTextAlignment(.center)
            .keyboardType(.numberPad)
            .frame(maxWidth: .infinity, minHeight: 40)
            .foregroundColor(isCompleted ? .green : .white)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.gray.opacity(0.3), lineWidth: 2)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.black.opacity(0.3))
                    )
            )
            .onChange(of: reps) { _, newValue in
                onChange(String(newValue))
            }
    }
}

fileprivate struct WeightTextField: View {
    @Binding var weight: Double
    @FocusState.Binding var focusedField: ExerciseExecutionView.Field?
    let index: Int
    let isCompleted: Bool
    let onChange: (String) -> Void
    
    var body: some View {
        TextField("14", value: $weight, format: .number)
            .focused($focusedField, equals: .weight(index: index))
            .font(.system(size: 24, weight: .bold, design: .default))
            .multilineTextAlignment(.center)
            .keyboardType(.decimalPad)
            .frame(maxWidth: .infinity, minHeight: 40)
            .foregroundColor(isCompleted ? .green : .white)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.gray.opacity(0.3), lineWidth: 2)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.black.opacity(0.3))
                    )
            )
            .onChange(of: weight) { _, newValue in
                onChange(String(Int(newValue)))
            }
    }
}
