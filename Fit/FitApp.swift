import SwiftUI
import SwiftData

@main
struct FitApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Workout.self,
            Exercise.self,
            WorkoutExercise.self,
            ExerciseSet.self,
            PersonalRecord.self,
            UserProfile.self,
            OneRepMaxHistory.self
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        do {
            AppLogger.info(AppLogger.app, "Initializing SwiftData ModelContainer")
            
            let container = try ModelContainer(for: schema, configurations: [modelConfiguration])
            let context = ModelContext(container)
            
            // Check if exercises exist, and delete them if none found
            let exercises = try context.fetch(FetchDescriptor<Exercise>())
            if exercises.isEmpty {
                AppLogger.debug(AppLogger.app, "No exercises found, loading from JSON")
                try ExerciseLoader.loadExercisesFromJSON(context: context)
            } else {
                AppLogger.debug(AppLogger.app, "Found \(exercises.count) existing exercises")
            }
            
            // --- Add a sample predefined workout if not already present ---
            let predefinedWorkouts = try context.fetch(FetchDescriptor<Workout>(predicate: #Predicate { $0.isPredefined == true }))
            if predefinedWorkouts.isEmpty {
                // Find some exercises to use in the sample workout
                let sampleExercises = exercises.prefix(3)
                if sampleExercises.count == 3 {
                    let workout = Workout(
                        name: "Full Body Starter",
                        isPredefined: true,
                        workoutDescription: "A simple full body workout for beginners.",
                        difficulty: .beginner,
                        tags: ["full body", "beginner"]
                    )
                    for (index, exercise) in sampleExercises.enumerated() {
                        let workoutExercise = WorkoutExercise(exercise: exercise, order: index + 1)
                        // Add a default set for each exercise
                        let set = ExerciseSet(setNumber: 1, weight: 20, reps: 10)
                        workoutExercise.sets.append(set)
                        workout.exercises.append(workoutExercise)
                    }
                    context.insert(workout)
                    try context.save()
                    AppLogger.info(AppLogger.app, "Sample predefined workout created.")
                } else {
                    AppLogger.fault(AppLogger.app, "Not enough exercises to create sample predefined workout.")
                }
            }
            AppLogger.debug(AppLogger.app, "ModelContainer created successfully")
            return container
          } catch {
              AppLogger.fault(AppLogger.app, "Failed to create ModelContainer", error: error)
              fatalError("Could not create ModelContainer: \(error)")
          }
      }()

    @State private var selectedTab = 0

    var body: some Scene {
        WindowGroup {
            TabView(selection: $selectedTab) {
                NavigationStack {
                    WorkoutView()
                        .background(Color.black)
                        .toolbarBackground(Color.black, for: .navigationBar)
                        .toolbarBackground(.visible, for: .navigationBar)
                }
                .tabItem { Label("Workout", systemImage: "figure.strengthtraining.traditional") }
                .tag(0)

                NavigationStack {
                    StatisticsView()
                        .background(Color.black)
                        .toolbarBackground(Color.black, for: .navigationBar)
                        .toolbarBackground(.visible, for: .navigationBar)
                }
                .tabItem { Label("Statistics", systemImage: "chart.xyaxis.line") }
                .tag(1)

                NavigationStack {
                    LogView()
                        .background(Color.black)
                        .toolbarBackground(Color.black, for: .navigationBar)
                        .toolbarBackground(.visible, for: .navigationBar)
                }
                .tabItem { Label("Log", systemImage: "list.clipboard") }
                .tag(2)

                NavigationStack {
                    DataManagementView()
                        .background(Color.black)
                        .toolbarBackground(Color.black, for: .navigationBar)
                        .toolbarBackground(.visible, for: .navigationBar)
                }
                .tabItem { Label("Data", systemImage: "server.rack") }
                .tag(3)
            }
            .tint(AppTheme.tintColor)
            .preferredColorScheme(.dark)
            .toolbarBackground(Color.black, for: .tabBar)
            .toolbarBackground(.visible, for: .tabBar)
            .onReceive(NotificationCenter.default.publisher(for: .switchToWorkoutTab)) { _ in
                selectedTab = 0
            }
        }
        .modelContainer(sharedModelContainer)
    }
}

