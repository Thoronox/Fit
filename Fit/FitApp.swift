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
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false, cloudKitDatabase: .automatic)
        do {
            AppLogger.info(AppLogger.app, "Initializing SwiftData ModelContainer")
            
            let container = try ModelContainer(for: schema, configurations: [modelConfiguration])
            let context = ModelContext(container)

            do {
                try ExerciseLoader.loadExercisesFromJSON(context: context)
                AppLogger.info(AppLogger.app, "Exercises loaded successfully from JSON")
                
                try ExerciseLoader.createPredefinedWorkout(context: context)
            } catch {
                AppLogger.error(AppLogger.app, "Failed to load exercises from JSON", error: error)
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
                    SettingsView()
                        .background(Color.black)
                        .toolbarBackground(Color.black, for: .navigationBar)
                        .toolbarBackground(.visible, for: .navigationBar)
                }
                .tabItem { Label("Settings", systemImage: "server.rack") }
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

