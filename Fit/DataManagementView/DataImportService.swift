import Foundation
import SwiftData

/// Service responsible for importing workout data from JSON files
struct DataImportService {
    
    /// Imports data from a JSON file into the model context
    /// - Parameters:
    ///   - fileURL: The URL of the JSON file to import
    ///   - modelContext: The SwiftData model context to import into
    /// - Throws: DataManagementError if import fails
    static func importData(from fileURL: URL, into modelContext: ModelContext) throws {
        AppLogger.info(AppLogger.data, "Starting data import from file: \(fileURL.lastPathComponent)")
        
        // Access the file
        let isSecured = fileURL.startAccessingSecurityScopedResource()
        defer {
            if isSecured {
                fileURL.stopAccessingSecurityScopedResource()
            }
        }
        
        // Read and validate the file
        let jsonData = try Data(contentsOf: fileURL)
        guard let json = try JSONSerialization.jsonObject(with: jsonData) as? [String: Any] else {
            AppLogger.error(AppLogger.data, "File is not valid JSON format")
            throw DataManagementError.invalidJSON
        }
        
        // Validate it's an export file from this app
        guard json["exportDate"] != nil else {
            AppLogger.error(AppLogger.data, "File doesn't appear to be a valid Fit export")
            throw DataManagementError.invalidExportFile
        }
        
        AppLogger.debug(AppLogger.data, "Successfully read JSON from file")
        
        // Clear existing data before importing
        AppLogger.debug(AppLogger.data, "Clearing existing data before import")
        try DataCleanupService.clearAllData(from: modelContext)
        
        // Import data in correct order
        try importExercises(from: json, into: modelContext)
        try importUserProfiles(from: json, into: modelContext)
        try modelContext.save()
        
        try importWorkouts(from: json, into: modelContext)
        try importPersonalRecords(from: json, into: modelContext)
        try importOneRepMaxHistory(from: json, into: modelContext)
        
        // Final save
        try modelContext.save()
        
        AppLogger.info(AppLogger.data, "Data import completed successfully from \(fileURL.lastPathComponent)")
    }
    
    // MARK: - Private Import Methods
    
    private static func importExercises(from json: [String: Any], into modelContext: ModelContext) throws {
        guard let exercisesData = json["exercises"] as? [[String: Any]] else { return }
        
        AppLogger.debug(AppLogger.data, "Found \(exercisesData.count) exercises to import")
        var importedCount = 0
        var seenIDs = Set<String>()
        
        for exerciseDict in exercisesData {
            if let exercise = DataRestoreService.restoreExercise(from: exerciseDict) {
                let idString = exercise.id.uuidString
                
                // Check for duplicates in the import data
                if seenIDs.contains(idString) {
                    AppLogger.warning(AppLogger.data, "Skipping duplicate exercise ID in import file: \(idString) - \(exercise.name)")
                    continue
                }
                
                seenIDs.insert(idString)
                modelContext.insert(exercise)
                importedCount += 1
            }
        }
        
        AppLogger.debug(AppLogger.data, "Imported \(importedCount) exercises (skipped \(exercisesData.count - importedCount) duplicates/invalid)")
    }
    
    private static func importUserProfiles(from json: [String: Any], into modelContext: ModelContext) throws {
        guard let profilesData = json["userProfiles"] as? [[String: Any]] else { return }
        
        AppLogger.debug(AppLogger.data, "Found \(profilesData.count) user profiles to import")
        
        for profileDict in profilesData {
            if let profile = DataRestoreService.restoreUserProfile(from: profileDict) {
                modelContext.insert(profile)
            }
        }
    }
    
    private static func importWorkouts(from json: [String: Any], into modelContext: ModelContext) throws {
        guard let workoutsData = json["workouts"] as? [[String: Any]] else { return }
        
        AppLogger.debug(AppLogger.data, "Found \(workoutsData.count) workouts to import")
        
        // Build exercise lookup for workout restoration
        let exercises = try modelContext.fetch(FetchDescriptor<Exercise>())
        var exerciseLookup: [String: Exercise] = [:]
        for exercise in exercises {
            let key = exercise.id.uuidString
            if exerciseLookup[key] == nil {
                exerciseLookup[key] = exercise
            }
        }
        
        for workoutDict in workoutsData {
            if let workout = DataRestoreService.restoreWorkout(from: workoutDict, exerciseLookup: exerciseLookup) {
                modelContext.insert(workout)
            }
        }
        
        AppLogger.debug(AppLogger.data, "Imported workouts with their exercises and sets")
    }
    
    private static func importPersonalRecords(from json: [String: Any], into modelContext: ModelContext) throws {
        guard let recordsData = json["personalRecords"] as? [[String: Any]] else { return }
        
        AppLogger.debug(AppLogger.data, "Found \(recordsData.count) personal records to import")
        
        // Build exercise lookup - handle duplicates by keeping first occurrence
        let exercises = try modelContext.fetch(FetchDescriptor<Exercise>())
        var exerciseLookup: [String: Exercise] = [:]
        for exercise in exercises {
            let key = exercise.id.uuidString
            if exerciseLookup[key] != nil {
                AppLogger.warning(AppLogger.data, "Duplicate exercise ID found: \(key), keeping first occurrence")
            } else {
                exerciseLookup[key] = exercise
            }
        }
        
        AppLogger.debug(AppLogger.data, "Built exercise lookup with \(exerciseLookup.count) unique exercises")
        
        for recordDict in recordsData {
            if let record = DataRestoreService.restorePersonalRecord(from: recordDict, exerciseLookup: exerciseLookup) {
                modelContext.insert(record)
            }
        }
    }
    
    private static func importOneRepMaxHistory(from json: [String: Any], into modelContext: ModelContext) throws {
        guard let historyData = json["oneRepMaxHistory"] as? [[String: Any]] else { return }
        
        AppLogger.debug(AppLogger.data, "Found \(historyData.count) 1RM history entries to import")
        
        // Build exercise lookup - handle duplicates by keeping first occurrence
        let exercises = try modelContext.fetch(FetchDescriptor<Exercise>())
        var exerciseLookup: [String: Exercise] = [:]
        for exercise in exercises {
            let key = exercise.id.uuidString
            if exerciseLookup[key] != nil {
                AppLogger.warning(AppLogger.data, "Duplicate exercise ID found: \(key), keeping first occurrence")
            } else {
                exerciseLookup[key] = exercise
            }
        }
        
        AppLogger.debug(AppLogger.data, "Built exercise lookup with \(exerciseLookup.count) unique exercises")
        
        for historyDict in historyData {
            if let history = DataRestoreService.restoreOneRepMaxHistory(from: historyDict, exerciseLookup: exerciseLookup) {
                modelContext.insert(history)
            }
        }
    }
}
