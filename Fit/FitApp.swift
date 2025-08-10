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
            WorkoutTemplate.self,
            TemplateExercise.self,
            PersonalRecord.self,
            UserProfile.self
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(.dark)
        }
        .modelContainer(sharedModelContainer)
    }
}
