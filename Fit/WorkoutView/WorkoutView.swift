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
    @State private var showTokenConfiguration = false
    @State private var workoutGenerator: AIWorkoutGeneratorService?
    @State private var showPredefinedSheet = false
    @Query(filter: #Predicate<Workout> { $0.isPredefined == true }) private var predefinedWorkouts: [Workout]
    
    // Get the selected provider
    @AppStorage("selectedAIProvider") var selectedProvider: AIProvider = .chatGPT
    @AppStorage("selectedChatGPTModel") var selectedChatGPTModel: ChatGPTModel = .gpt5Nano

    var body: some View {
        VStack {
            headerSection
            criteriaSection
            workoutContentSection
            startWorkoutButton
        }
        .toolbar(.hidden, for: .navigationBar)
        .onAppear(perform: handleOnAppear)
        .onChange(of: criteria.durationSelected) { generateWorkout(modelContext: modelContext) }
        .onChange(of: criteria.trainingTypeSelected) { generateWorkout(modelContext: modelContext) }
        .onChange(of: criteria.difficultySelected) { generateWorkout(modelContext: modelContext) }
        .onChange(of: criteria.workoutSplitSelected) { generateWorkout(modelContext: modelContext) }
        .fullScreenCover(isPresented: $startWorkout) {
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
        .onReceive(NotificationCenter.default.publisher(for: .workoutCreated)) { notification in
            if let userInfo = notification.userInfo,
               let workout = userInfo["workout"] as? Workout {
                currentWorkout = workout
            }
        }
        .fullScreenCover(item: $selectedWorkoutExercise) { workoutExercise in
            ExerciseExecutionView(workoutExercise: workoutExercise, readonly: true)
        }
        .fullScreenCover(isPresented: $showPredefinedSheet) {
            PredefinedWorkoutListView(
                workouts: predefinedWorkouts,
                onSelect: { selected in
                    if let selected = selected {
                        currentWorkout = selected
                    }
                    showPredefinedSheet = false
                }
            )
        }
    }
    
    // MARK: - View Components
    
    @ViewBuilder
    private var headerSection: some View {
        HStack {
            Text("Workout")
                .font(.largeTitle)
                .bold()
            Spacer()
            Button(action: { showPredefinedSheet = true }) {
                Image(systemName: "plus")
            }
            .font(.title2)
            .accessibilityLabel("Show Predefined Workouts")
        }
        .padding(.horizontal)
    }
    
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
            if showTokenConfiguration == true {
                VStack {
                    Spacer()
                    Text("You need to configure the AI provider and the API token in the Settings first.")
                    Spacer()
                }
            } else {
                ProgressView("Loading new workout from \(selectedProvider == .chatGPT ? "ChatGPT" : "Gemini")...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
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
            NavigationStack {
                StartWorkoutView(workout: workout)
                    .background(Color.black)
                    .toolbarBackground(Color.black, for: .navigationBar)
                    .toolbarBackground(.visible, for: .navigationBar)
            }
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
        let token = KeychainHelper.load(key: selectedProvider == .chatGPT ? "chatGPTAPIToken" : "geminiAPIToken")

        print (selectedChatGPTModel)
        

        if token == nil {
            currentWorkout = nil
            showTokenConfiguration = true
            return
        } else {
            showTokenConfiguration = false
        }
        
        // Unwrap token safely
        guard let unwrappedToken = token else { return }
        
        if workoutGenerator == nil {
            if selectedProvider == .chatGPT {
                workoutGenerator = ChatGPTWorkoutGeneratorService(apiKey: unwrappedToken, model: selectedChatGPTModel.id)
            } else {
                workoutGenerator = GeminiWorkoutGeneratorService(apiKey: unwrappedToken)
            }
        }
        
        if currentWorkout == nil {
            Task {
                generateWorkout(modelContext: modelContext)
            }
        }
    }
    
    private func generateWorkout(modelContext: ModelContext) {
        //currentWorkout = computeNewWorkout()
        let token = KeychainHelper.load(key: selectedProvider == .chatGPT ? "chatGPTAPIToken" : "geminiAPIToken")

        // Ensure we have a token
        guard let unwrappedToken = token else {
            showTokenConfiguration = true
            return
        }

        if workoutGenerator == nil {
            workoutGenerator = GeminiWorkoutGeneratorService(apiKey: unwrappedToken)
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
    static let workoutCreated = Notification.Name("workoutCreated")
    static let switchToWorkoutTab = Notification.Name("switchToWorkoutTab")
}


struct PredefinedWorkoutListView: View {
    let workouts: [Workout]
    let onSelect: (Workout?) -> Void
    @Environment(\.dismiss) private var dismiss
    var body: some View {
        NavigationStack {
            List(workouts) { workout in
                Button(action: { onSelect(workout) }) {
                    VStack(alignment: .leading) {
                        Text(workout.name)
                        if let desc = workout.workoutDescription {
                            Text(desc).font(.caption).foregroundColor(.secondary)
                        }
                    }
                }
            }
            .navigationTitle("Predefined Workouts")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { onSelect(nil) }
                }
            }
        }
    }
}

#Preview {
    let previewData = PreviewData.create()
    
    NavigationStack {
        WorkoutView()
            .modelContainer(previewData.container)
            .preferredColorScheme(.dark)
    }
}
