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
    @Query private var exercises: [Exercise]

    @StateObject private var criteria = WorkoutCriteria()

    @State private var startWorkout: Bool = false
    @State private var currentWorkout: Workout?
    @State private var selectedExerciseForDetails: WorkoutExercise?

    var body: some View {
        VStack(spacing: 0) {
            criteriaSection
            workoutContentSection
            startWorkoutButton
        }
        .navigationTitle("Workout")
        .navigationBarTitleDisplayMode(.large)
        .onAppear(perform: handleOnAppear)
        .onReceive(criteria.objectWillChange) { _ in
            generateWorkout(modelContext: modelContext)
        }
        .fullScreenCover(isPresented: $startWorkout) {
            workoutSheet
        }
        .sheet(item: $selectedExerciseForDetails) { workoutExercise in
            ExerciseDetailsView(workoutExercise: workoutExercise)
        }
        .onReceive(NotificationCenter.default.publisher(for: .workoutFinished)) { _ in
            currentWorkout = computeNewWorkout()
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
                StaticExerciseView(workoutExercise: workoutExercise)
                    .listRowInsets(EdgeInsets())
                    .listRowSeparator(.visible, edges: .bottom)
                    .alignmentGuide(.listRowSeparatorLeading) { _ in 0 }
                    .listRowBackground(Color.clear)
                    .padding()
                    .contentShape(Rectangle())
                    .onTapGesture {
                        selectedExerciseForDetails = workoutExercise
                    }
            }
        }
        .listStyle(.plain)
    }
    
    @ViewBuilder
    private var loadingOrErrorSection: some View {
        ProgressView("Loading new workout...")
            .frame(maxWidth: .infinity, maxHeight: .infinity)
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
    
    // MARK: - Helper Methods
    
    private func handleOnAppear() {
        if currentWorkout == nil {
            generateWorkout(modelContext: modelContext)
        }
    }

    private func generateWorkout(modelContext: ModelContext) {
        currentWorkout = computeNewWorkout()
    }
    
    private func computeNewWorkout() -> Workout {
        let newWorkout = Workout(name: "Workout", date: Date())
        
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
}

extension Notification.Name {
    static let workoutFinished = Notification.Name("workoutFinished")
}

#Preview {
    NavigationStack {
        WorkoutView()
            .modelContainer(for: [Exercise.self, Workout.self, WorkoutExercise.self, ExerciseSet.self]) { result in
                if case .success(let container) = result {
                    let context = container.mainContext
                    
                    // Create sample exercises with valid UUID strings
                    let exercise1 = Exercise(id: "A1B2C3D4-E5F6-7890-ABCD-EF1234567890", name: "Bench Press", primaryMuscleGroup: .chest, exerciseType: .strength)
                    exercise1.equipment = .barbell
                    exercise1.isCompound = true
                    exercise1.instructions = "Lie on a flat bench with your feet flat on the ground. Grip the bar with hands slightly wider than shoulder-width apart."
                    
                    let exercise2 = Exercise(id: "B2C3D4E5-F6A7-8901-BCDE-F12345678901", name: "Barbell Squat", primaryMuscleGroup: .quadriceps, exerciseType: .strength)
                    exercise2.equipment = .barbell
                    exercise2.isCompound = true
                    exercise2.secondaryMuscleGroups = [.glutes, .hamstrings]
                    
                    let exercise3 = Exercise(id: "C3D4E5F6-A7B8-9012-CDEF-123456789012", name: "Deadlift", primaryMuscleGroup: .back, exerciseType: .strength)
                    exercise3.equipment = .barbell
                    exercise3.isCompound = true
                    exercise3.secondaryMuscleGroups = [.hamstrings, .glutes]
                    
                    let exercise4 = Exercise(id: "D4E5F6A7-B8C9-0123-DEF1-234567890123", name: "Overhead Press", primaryMuscleGroup: .shoulders, exerciseType: .strength)
                    exercise4.equipment = .barbell
                    exercise4.isCompound = true
                    exercise4.secondaryMuscleGroups = [.triceps]
                    
                    // Insert exercises into context
                    context.insert(exercise1)
                    context.insert(exercise2)
                    context.insert(exercise3)
                    context.insert(exercise4)
                    
                    // Save the context
                    try? context.save()
                }
            }
    }
}
