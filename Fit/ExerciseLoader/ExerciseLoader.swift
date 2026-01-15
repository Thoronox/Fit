import Foundation
import SwiftData

// MARK: - JSON Data Structure
struct ExerciseData: Codable {
    let id: String
    let name: String
    let instructions: String?
    let primaryMuscleGroup: String
    let secondaryMuscleGroups: [String]
    let equipment: String
    let exerciseType: String
    let isCompound: Bool
}

class ExerciseLoader {
    static func createPredefinedWorkout(context: ModelContext) throws {
        // --- Add or update sample predefined workout ---
        let exercises = try context.fetch(FetchDescriptor<Exercise>())
        let predefinedWorkouts = try context.fetch(FetchDescriptor<Workout>(predicate: #Predicate { $0.isPredefined == true && $0.name == "Full Body Starter" }))
        
        // Find specific exercises to use in the sample workout
        let exerciseNames = [
            "Incline Dumbbell Bench Press",
            "Goblet Squat",
            "Pull-up",
            "Dumbbell Romanian Deadlift",
            "Barbell Row",
            "Dumbbell Lateral Raise"
        ]
        
        let sampleExercises = exerciseNames.compactMap { name in
            exercises.first { $0.name == name }
        }
        
        if sampleExercises.count == exerciseNames.count {
            let workout: Workout
            
            if let existingWorkout = predefinedWorkouts.first {
                // Update existing workout
                workout = existingWorkout
                workout.workoutDescription = "A simple full body workout for beginners."
                workout.difficulty = .beginner
                workout.tags = ["full body", "beginner"]
                
                // Clear existing exercises
                workout.exercises.removeAll()
                AppLogger.info(AppLogger.app, "Updating existing predefined workout.")
            } else {
                // Create new workout
                workout = Workout(
                    name: "Full Body Starter",
                    isPredefined: true,
                    workoutDescription: "A simple full body workout for beginners.",
                    difficulty: .beginner,
                    tags: ["full body", "beginner"]
                )
                context.insert(workout)
                AppLogger.info(AppLogger.app, "Creating new predefined workout.")
            }
            
            // Add exercises and sets
            for (index, exercise) in sampleExercises.enumerated() {
                let workoutExercise = WorkoutExercise(exercise: exercise, order: index + 1)
                // Add 3 sets for each exercise
                for setNumber in 1...3 {
                    let set = ExerciseSet(setNumber: setNumber, weight: 20, reps: 10)
                    workoutExercise.sets.append(set)
                }
                workout.exercises.append(workoutExercise)
            }
            
            try context.save()
            AppLogger.info(AppLogger.app, "Sample predefined workout saved.")
        } else {
            AppLogger.fault(AppLogger.app, "Not all required exercises found to create sample predefined workout.")
        }
    }
    
    /// Loads exercises from the JSON file and creates/updates Exercise objects
    /// - Parameter context: The ModelContext to insert/update the exercises
    /// - Returns: Array of Exercise objects (both new and updated)
    static func loadExercisesFromJSON(context: ModelContext) throws  {
        guard let url = Bundle.main.url(forResource: "exercises", withExtension: "json") else {
            throw ExerciseLoaderError.fileNotFound
        }
        
        let data = try Data(contentsOf: url)
        let exerciseDataArray = try JSONDecoder().decode([ExerciseData].self, from: data)
        
        // Fetch all existing exercises
        let descriptor = FetchDescriptor<Exercise>()
        let existingExercises = try context.fetch(descriptor)
        
        // Create a dictionary for quick lookup by name
        var existingExercisesByName: [String: Exercise] = [:]
        for exercise in existingExercises {
            existingExercisesByName[exercise.name] = exercise
        }
        
        var exercises: [Exercise] = []
        
        for exerciseData in exerciseDataArray {
            if let existingExercise = existingExercisesByName[exerciseData.name] {
                // Update existing exercise
                updateExercise(existingExercise, from: exerciseData)
                exercises.append(existingExercise)
            } else {
                // Create new exercise
                let newExercise = createExercise(from: exerciseData)
                context.insert(newExercise)
                exercises.append(newExercise)
            }
        }
    }
    
    /// Creates an Exercise object from ExerciseData
    private static func createExercise(from data: ExerciseData) -> Exercise {
        // Convert string to MuscleGroup enum
        let primaryMuscleGroup = MuscleGroup(rawValue: data.primaryMuscleGroup) ?? .fullBody
        
        // Convert string to ExerciseType enum
        let exerciseType = ExerciseType(rawValue: data.exerciseType) ?? .strength
        
        // Create the exercise
        let exercise = Exercise(
            id: data.id,
            name: data.name,
            primaryMuscleGroup: primaryMuscleGroup,
            exerciseType: exerciseType
        )
        
        // Set additional properties
        exercise.instructions = data.instructions
        exercise.isCompound = data.isCompound
        
        // Convert equipment string to Equipment enum
        exercise.equipment = Equipment(rawValue: data.equipment)
        
        // Convert secondary muscle groups
        exercise.secondaryMuscleGroups = data.secondaryMuscleGroups.compactMap {
            MuscleGroup(rawValue: $0)
        }
        
        return exercise
    }
    
    /// Updates an existing Exercise object with data from ExerciseData
    private static func updateExercise(_ exercise: Exercise, from data: ExerciseData) {
        // Update primary muscle group
        if let primaryMuscleGroup = MuscleGroup(rawValue: data.primaryMuscleGroup) {
            exercise.primaryMuscleGroup = primaryMuscleGroup
        }
        
        // Update exercise type
        if let exerciseType = ExerciseType(rawValue: data.exerciseType) {
            exercise.exerciseType = exerciseType
        }
        
        // Update other properties
        exercise.instructions = data.instructions
        exercise.isCompound = data.isCompound
        exercise.equipment = Equipment(rawValue: data.equipment)
        
        // Update secondary muscle groups
        exercise.secondaryMuscleGroups = data.secondaryMuscleGroups.compactMap {
            MuscleGroup(rawValue: $0)
        }
    }
    
    /// Deletes all exercises from the context
    static func deleteAllExercises(context: ModelContext) throws {
        AppLogger.info(AppLogger.exercise, "Deleting all exercises from database")
        let descriptor = FetchDescriptor<Exercise>()
        let exercises = try context.fetch(descriptor)
        
        for exercise in exercises {
            context.delete(exercise)
        }
        
        try context.save()
        AppLogger.info(AppLogger.exercise, "Successfully deleted \(exercises.count) exercises")
    }
    
    /// Deletes all exercises and reloads from JSON
    static func resetExercises(context: ModelContext) throws {
        AppLogger.warning(AppLogger.exercise, "Resetting all exercises - deleting and reloading from JSON")
        try deleteAllExercises(context: context)
        _ = try loadExercisesFromJSON(context: context)
        AppLogger.info(AppLogger.exercise, "Exercise reset completed")
    }
}



enum ExerciseLoaderError: Error, LocalizedError {
    case fileNotFound
    case invalidData
    case decodingError
    
    var errorDescription: String? {
        switch self {
        case .fileNotFound:
            return "Could not find the exercises JSON file in the app bundle"
        case .invalidData:
            return "The JSON file contains invalid data"
        case .decodingError:
            return "Failed to decode the JSON data"
        }
    }
}


