import SwiftUI

struct ExerciseExecutionView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @State private var setInputs: [SetInput] = []
    @State private var currentSetIndex = 0

    let workoutExercise: WorkoutExercise

    struct SetInput: Identifiable {
        let id = UUID()
        var reps: String
        var weight: String
        var isCompleted: Bool
        var setNumber: Int
    }

    fileprivate enum Field: Hashable {
        case reps(index: Int)
        case weight(index: Int)
    }
    @FocusState private var focusedField: Field?

    @State private var showPauseTimer = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                WorkoutTimerView()

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
            setupSetInputs()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                focusedField = .reps(index: currentSetIndex)
            }
        }
        .sheet(isPresented: $showPauseTimer) {
            ExercisePauseView(restTime: workoutExercise.restTime ?? 60)
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

            // Sets List
            List {
                ForEach($setInputs.indices, id: \.self) { index in
                    SetRowView(
                        input: $setInputs[index],
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
            .background(Color.red)
            .foregroundColor(.white)
            .font(.headline)
            .cornerRadius(12)
            .disabled(currentSetIndex >= setInputs.count ||
                     setInputs[currentSetIndex].reps.isEmpty ||
                     setInputs[currentSetIndex].weight.isEmpty)
        }
        .padding()
    }

    // MARK: - Logic

    private func setupSetInputs() {
        setInputs = workoutExercise.sets.enumerated().map { index, set in
            SetInput(
                reps: String(set.reps),
                weight: String(Int(set.weight)),
                isCompleted: set.isCompleted,
                setNumber: set.setNumber
            )
        }

        currentSetIndex = setInputs.firstIndex { !$0.isCompleted } ?? 0
    }

    private func addSet() {
        let newSetNumber = setInputs.count + 1
        let newSet = ExerciseSet(setNumber: newSetNumber, weight: 0, reps: 0)
        workoutExercise.sets.append(newSet)

        let newInput = SetInput(
            reps: "",
            weight: "",
            isCompleted: false,
            setNumber: newSetNumber
        )
        setInputs.append(newInput)
    }

    private func deleteSet(at index: Int) {
        // Don't allow deleting if there's only one set
        guard setInputs.count > 1, index < setInputs.count else { return }
        
        // Remove from both the UI state and the data model
        setInputs.remove(at: index)
        
        if index < workoutExercise.sets.count {
            workoutExercise.sets.remove(at: index)
        }
        
        // Update set numbers for remaining sets
        for (newIndex, _) in setInputs.enumerated() {
            setInputs[newIndex].setNumber = newIndex + 1
            if newIndex < workoutExercise.sets.count {
                workoutExercise.sets[newIndex].setNumber = newIndex + 1
            }
        }
        
        // Adjust currentSetIndex if necessary
        if currentSetIndex >= setInputs.count {
            currentSetIndex = max(0, setInputs.count - 1)
        }
        
        // Find the next incomplete set
        if let nextIncompleteIndex = setInputs.firstIndex(where: { !$0.isCompleted }) {
            currentSetIndex = nextIncompleteIndex
        }
    }

    // MARK: - Propagation Methods
    
    private func propagateRepsToBelow(fromIndex: Int, value: String) {
        guard fromIndex < setInputs.count else { return }
        
        for index in (fromIndex + 1)..<setInputs.count {
            if !setInputs[index].isCompleted {
                setInputs[index].reps = value
            }
        }
    }
    
    private func propagateWeightToBelow(fromIndex: Int, value: String) {
        guard fromIndex < setInputs.count else { return }
        
        for index in (fromIndex + 1)..<setInputs.count {
            if !setInputs[index].isCompleted {
                setInputs[index].weight = value
            }
        }
    }

    private func logAllSets() {
        for (index, input) in setInputs.enumerated() {
            guard index < workoutExercise.sets.count else { continue }

            let set = workoutExercise.sets[index]

            if let repsValue = Int(input.reps), let weightValue = Double(input.weight) {
                set.reps = repsValue
                set.weight = weightValue
                set.isCompleted = true

                setInputs[index].isCompleted = true
            }
        }
        dismiss()
    }

    private func logCurrentSet() {
        guard currentSetIndex < setInputs.count else { return }
        let input = setInputs[currentSetIndex]
        guard let repsValue = Int(input.reps),
              let weightValue = Double(input.weight),
              currentSetIndex < workoutExercise.sets.count else { return }

        let set = workoutExercise.sets[currentSetIndex]
        set.reps = repsValue
        set.weight = weightValue
        set.isCompleted = true
        setInputs[currentSetIndex].isCompleted = true

        if currentSetIndex < setInputs.count - 1 {
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
    @Binding var input: ExerciseExecutionView.SetInput
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

                Text(input.isCompleted ?  "✓" : "\(index + 1)")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(input.isCompleted ? .green : .white)
            }

            // Reps Input
            RepsTextField(
                text: $input.reps,
                focusedField: $focusedField,
                index: index,
                onChange: onRepsChange
            )
            .foregroundColor(input.isCompleted ? .green : .white)

            // Weight Input
            WeightTextField(
                text: $input.weight,
                focusedField: $focusedField,
                index: index,
                onChange: onWeightChange
            )
            .foregroundColor(input.isCompleted ? .green : .white)
        }
    }
}

fileprivate struct RepsTextField: View {
    @Binding var text: String
    @FocusState.Binding var focusedField: ExerciseExecutionView.Field?
    let index: Int
    let onChange: (String) -> Void

    var body: some View {
        TextField("6", text: $text)
            .focused($focusedField, equals: .reps(index: index))
            .font(.system(size: 24, weight: .bold, design: .default))
            .multilineTextAlignment(.center)
            .keyboardType(.numberPad)
            .frame(maxWidth: .infinity, minHeight: 40)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.gray.opacity(0.3), lineWidth: 2)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.black.opacity(0.3))
                    )
            )
            .onChange(of: text) { _, newValue in
                onChange(newValue)
            }
    }
}

fileprivate struct WeightTextField: View {
    @Binding var text: String
    @FocusState.Binding var focusedField: ExerciseExecutionView.Field?
    let index: Int
    let onChange: (String) -> Void

    var body: some View {
        TextField("14", text: $text)
            .focused($focusedField, equals: .weight(index: index))
            .font(.system(size: 24, weight: .bold, design: .default))
            .multilineTextAlignment(.center)
            .keyboardType(.decimalPad)
            .frame(maxWidth: .infinity, minHeight: 40)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.gray.opacity(0.3), lineWidth: 2)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.black.opacity(0.3))
                    )
            )
            .onChange(of: text) { _, newValue in
                onChange(newValue)
            }
    }
}

// MARK: - Make WorkoutExercise Identifiable for sheet presentation
extension WorkoutExercise: Identifiable {}
extension Workout: Identifiable {}
