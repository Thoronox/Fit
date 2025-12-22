import SwiftUI
import SwiftData

class WorkoutCriteria: ObservableObject {
    @Published var durationSelected = "45 min"
    @Published var trainingTypeSelected = "Hypertrophy"
    @Published var difficultySelected = "Intermediate"
    @Published var workoutSplitSelected = "Full Body"
}

struct WorkoutView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Workout.date, order: .reverse) private var workouts: [Workout]
    @Query private var exercises: [Exercise]

    @StateObject private var criteria = WorkoutCriteria()

    @State private var startWorkout: Bool = false
    @State private var selectedWorkoutExercise: WorkoutExercise?
    @State private var currentWorkout: Workout?
    @State private var exerciseToDelete: WorkoutExercise?
    @State private var showDeleteAlert = false
    @State private var showRetry = false
    @State private var workoutGenerator: GeminiWorkoutGeneratorService?

    var body: some View {
        VStack {
            criteriaSection
            workoutContentSection
            startWorkoutButton
        }
        .navigationTitle("Workout")
        .onAppear(perform: handleOnAppear)
        .onChange(of: criteria.durationSelected) { generateWorkout(modelContext: modelContext) }
        .onChange(of: criteria.trainingTypeSelected) { generateWorkout(modelContext: modelContext) }
        .onChange(of: criteria.difficultySelected) { generateWorkout(modelContext: modelContext) }
        .onChange(of: criteria.workoutSplitSelected) { generateWorkout(modelContext: modelContext) }
        .sheet(isPresented: $startWorkout) {
            workoutSheet
        }
        .alert("Delete Exercise", isPresented: $showDeleteAlert) {
            deleteAlert
        } message: {
            deleteAlertMessage
        }
        .onReceive(NotificationCenter.default.publisher(for: .workoutFinished)) { _ in
            currentWorkout = nil
        }
        .sheet(item: $selectedWorkoutExercise) { workoutExercise in
            ExerciseExecutionView(workoutExercise: workoutExercise, readonly: true)
        }
    }
    
    // MARK: - View Components
    
    @ViewBuilder
    private var criteriaSection: some View {
        WorkoutCriteriaView()
            .environmentObject(criteria)
    }
    
    @ViewBuilder
    private var workoutContentSection: some View {
        if let workout = currentWorkout {
            workoutList(for: workout)
        } else {
            loadingOrErrorSection
        }
    }
    
    @ViewBuilder
    private func workoutList(for workout: Workout) -> some View {
        List {
            ForEach(workout.exercises.sorted(by: { $0.order < $1.order })) { workoutExercise in
                WorkoutExerciseView(
                    workoutExercise: workoutExercise,
                )
                .listRowBackground(Color.black)
            }
        }
        .listStyle(.plain)
    }
    
    @ViewBuilder
    private var loadingOrErrorSection: some View {
        if showRetry == false {
            ProgressView("Loading new workout...")
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            VStack {
                Spacer()
                Text("Error loading AI generated workout")
                retryButton
                Spacer()
            }
        }
    }
    
    @ViewBuilder
    private var retryButton: some View {
        Button("Retry") {
            showRetry = false
            Task {
                generateWorkout(modelContext: modelContext)
            }
        }
        .buttonStyle(.borderedProminent)
        .padding(.bottom)
    }
    
    @ViewBuilder
    private var startWorkoutButton: some View {
        Button("Start Workout") {
            if currentWorkout == nil {
                currentWorkout = computeNewWorkout()
            }
            startWorkout = true
        }
        .buttonStyle(.borderedProminent)
        .padding(.bottom)
    }
    
    @ViewBuilder
    private var workoutSheet: some View {
        if let workout = currentWorkout {
            StartWorkoutView(workout: workout)
        }
    }
    
    @ViewBuilder
    private var deleteAlert: some View {
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
    }
    
    @ViewBuilder
    private var deleteAlertMessage: some View {
        Text("Are you sure you want to delete \(exerciseToDelete?.exercise?.name ?? "this exercise")? This action cannot be undone.")
    }
    
    // MARK: - Helper Methods
    
    private func handleOnAppear() {
        if workoutGenerator == nil {
            workoutGenerator = GeminiWorkoutGeneratorService()
        }
        
        if currentWorkout == nil {
            Task {
                generateWorkout(modelContext: modelContext)
            }
        }
    }

    private func generateWorkout(modelContext: ModelContext) {
        currentWorkout = computeNewWorkout()
/*
        if workoutGenerator == nil {
            workoutGenerator = GeminiWorkoutGeneratorService()
        }
        
        guard let generator = workoutGenerator else { return }
        
        currentWorkout = nil
        Task {
            await generator.generateWorkout(
                modelContext: modelContext,
                duration: criteria.durationSelected,
                trainingType: criteria.trainingTypeSelected,
                difficulty: criteria.difficultySelected,
                workoutSplit: criteria.workoutSplitSelected,
                exercises: exercises
            )
            currentWorkout = generator.generatedWorkout

            if currentWorkout == nil {
                showRetry = true
            } else {
                showRetry = false
            }
        }
 */
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
        AppLogger.info(AppLogger.workout, "Deleting exercise '\(workoutExercise.exercise?.name ?? "Unknown")' from workout")
        withAnimation {
            if let index = workout.exercises.firstIndex(where: { $0.id == workoutExercise.id }) {
                workout.exercises.remove(at: index)
                reorderExercises(in: workout)
                AppLogger.debug(AppLogger.workout, "Exercise removed and remaining exercises reordered")
            }
        }
    }
    
    private func reorderExercises(in workout: Workout) {
        for (index, exercise) in workout.exercises.enumerated() {
            exercise.order = index
        }
    }
}

extension Notification.Name {
    static let workoutFinished = Notification.Name("workoutFinished")
}





