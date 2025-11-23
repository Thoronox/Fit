import Foundation
import SwiftData

/// Service responsible for cleaning up data from the model context
struct DataCleanupService {
    
    /// Deletes all data from the model context
    /// - Parameter modelContext: The SwiftData model context
    /// - Throws: Error if deletion fails
    static func clearAllData(from modelContext: ModelContext) throws {
        AppLogger.debug(AppLogger.data, "Clearing all data from modelContext")
        
        // Delete in correct order respecting relationships
        // Start with dependent models that have no inverse cascades
        
        // Delete PersonalRecords first (has no dependents)
        try modelContext.delete(model: PersonalRecord.self)
        AppLogger.debug(AppLogger.data, "Deleted PersonalRecords")
        
        // Delete OneRepMaxHistory (has no dependents)
        try modelContext.delete(model: OneRepMaxHistory.self)
        AppLogger.debug(AppLogger.data, "Deleted OneRepMaxHistory")
        
        // Delete Workouts (will cascade to WorkoutExercises and ExerciseSets)
        try modelContext.delete(model: Workout.self)
        AppLogger.debug(AppLogger.data, "Deleted Workouts (cascaded to WorkoutExercises and ExerciseSets)")
        
        // Delete UserProfiles (has no dependents)
        try modelContext.delete(model: UserProfile.self)
        AppLogger.debug(AppLogger.data, "Deleted UserProfiles")
        
        // Clean up any remaining orphaned items before deleting exercises
        try modelContext.delete(model: WorkoutExercise.self)
        try modelContext.delete(model: ExerciseSet.self)
        AppLogger.debug(AppLogger.data, "Deleted orphaned WorkoutExercises and ExerciseSets")
        
        // Delete Exercises LAST (referenced by PersonalRecord, OneRepMaxHistory, and WorkoutExercise)
        try modelContext.delete(model: Exercise.self)
        AppLogger.debug(AppLogger.data, "Deleted Exercises")
        
        AppLogger.debug(AppLogger.data, "All data cleared from modelContext")
    }
}
