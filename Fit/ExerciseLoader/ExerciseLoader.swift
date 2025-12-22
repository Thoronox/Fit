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

/*
// MARK: - Alternative: Load without inserting into context
extension ExerciseLoader {
    
    /// Loads exercises from JSON without inserting them into a ModelContext
    /// Useful if you want to process the data before saving
    static func loadExerciseDataFromJSON() throws -> [Exercise] {
        guard let url = Bundle.main.url(forResource: "paste-2", withExtension: "json") else {
            throw ExerciseLoaderError.fileNotFound
        }
        
        let data = try Data(contentsOf: url)
        let exerciseDataArray = try JSONDecoder().decode([ExerciseData].self, from: data)
        
        return exerciseDataArray.map { createExercise(from: $0) }
    }
    
    /// Batch insert exercises with better error handling
    static func loadAndInsertExercises(context: ModelContext) throws {
        let exercises = try loadExerciseDataFromJSON()
        
        // Check if exercises already exist to avoid duplicates
        let descriptor = FetchDescriptor<Exercise>()
        let existingExercises = try context.fetch(descriptor)
        let existingNames = Set(existingExercises.map { $0.name })
        
        let newExercises = exercises.filter { !existingNames.contains($0.name) }
        
        for exercise in newExercises {
            context.insert(exercise)
        }
        
        try context.save()
    }
}
*/
