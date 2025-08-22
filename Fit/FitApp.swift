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
            UserProfile.self,
            OneRepMaxHistory.self
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            
              let container = try ModelContainer(for: schema, configurations: [modelConfiguration])
              let context = ModelContext(container)

              // Helper function to delete all of a given type
              func deleteAll<T: PersistentModel>(_ type: T.Type) throws {
                  let allItems = try context.fetch(FetchDescriptor<T>())
                  for item in allItems {
                      context.delete(item)
                  }
              }

/*
              // Delete all entities
              try deleteAll(Workout.self)
              try deleteAll(Exercise.self)
              try deleteAll(WorkoutExercise.self)
              try deleteAll(ExerciseSet.self)
              try deleteAll(WorkoutTemplate.self)
              try deleteAll(TemplateExercise.self)
              try deleteAll(PersonalRecord.self)
              try deleteAll(UserProfile.self)
              try deleteAll(OneRepMaxHistory.self)


              try context.save()
*/
              return container
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
