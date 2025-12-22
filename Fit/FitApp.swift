//
//  FitApp.swift
//  Fit
//
//  Created by Flocken, Holger (CDO) on 01.08.25.
//

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
            
            AppLogger.debug(AppLogger.app, "ModelContainer created successfully")
            return container
          } catch {
              AppLogger.fault(AppLogger.app, "Failed to create ModelContainer", error: error)
              fatalError("Could not create ModelContainer: \(error)")
          }
      }()
    
    var body: some Scene {
        WindowGroup {
            TabView {
                NavigationStack {
                    WorkoutView()
                        .background(Color.black)
                        .toolbarBackground(Color.black, for: .navigationBar)
                        .toolbarBackground(.visible, for: .navigationBar)
                }
                .tabItem { Label("Workout", systemImage: "figure.strengthtraining.traditional") }
                
                NavigationStack {
                    StatisticsView()
                        .background(Color.black)
                        .toolbarBackground(Color.black, for: .navigationBar)
                        .toolbarBackground(.visible, for: .navigationBar)
                }
                .tabItem { Label("Statistics", systemImage: "chart.xyaxis.line") }
                
                NavigationStack {
                    LogView()
                        .background(Color.black)
                        .toolbarBackground(Color.black, for: .navigationBar)
                        .toolbarBackground(.visible, for: .navigationBar)
                }
                .tabItem { Label("Log", systemImage: "list.clipboard") }
                
                NavigationStack {
                    DataManagementView()
                        .background(Color.black)
                        .toolbarBackground(Color.black, for: .navigationBar)
                        .toolbarBackground(.visible, for: .navigationBar)
                }
                .tabItem { Label("Data", systemImage: "server.rack") }
            }
            .tint(AppTheme.tintColor)
            .preferredColorScheme(.dark)
            .toolbarBackground(Color.black, for: .tabBar)
            .toolbarBackground(.visible, for: .tabBar)
        }
        .modelContainer(sharedModelContainer)
    }
}
