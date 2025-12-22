import Foundation
import SwiftData

/// Service responsible for exporting workout data to JSON files
struct DataExportService {
    
    /// Exports all data from the model context to a temporary JSON file
    /// - Parameter modelContext: The SwiftData model context
    /// - Returns: URL of the created temporary file
    /// - Throws: DataManagementError if export fails
    static func exportData(from modelContext: ModelContext) throws -> URL {
        AppLogger.info(AppLogger.data, "Starting data export")
        
        // Fetch all data from modelContext
        let workouts = try modelContext.fetch(FetchDescriptor<Workout>())
        let exercises = try modelContext.fetch(FetchDescriptor<Exercise>())
        let personalRecords = try modelContext.fetch(FetchDescriptor<PersonalRecord>())
        let userProfiles = try modelContext.fetch(FetchDescriptor<UserProfile>())
        let oneRepMaxHistory = try modelContext.fetch(FetchDescriptor<OneRepMaxHistory>())
        
        // Validate there's data to export
        if workouts.isEmpty && exercises.isEmpty && personalRecords.isEmpty && userProfiles.isEmpty && oneRepMaxHistory.isEmpty {
            AppLogger.warning(AppLogger.data, "No data to export")
            throw DataManagementError.noDataToExport
        }
        
        AppLogger.debug(AppLogger.data, "Fetched \(workouts.count) workouts, \(exercises.count) exercises")
        
        // Convert models to dictionaries
        let exportData: [String: Any] = [
            "exercises": exercises.map { convertExercise($0) },
            "workouts": workouts.map { convertWorkout($0) },
            "userProfiles": userProfiles.map { convertUserProfile($0) },
            "personalRecords": personalRecords.map { convertPersonalRecord($0) },
            "oneRepMaxHistory": oneRepMaxHistory.map { convertOneRepMaxHistory($0) },
            "exportDate": ISO8601DateFormatter().string(from: Date())
        ]
        
        // Convert to JSON
        let jsonData = try JSONSerialization.data(withJSONObject: exportData, options: .prettyPrinted)
        
        // Create temporary file
        let tempDir = FileManager.default.temporaryDirectory
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd_HH-mm-ss"
        let filename = "fit_export_\(dateFormatter.string(from: Date())).json"
        let fileURL = tempDir.appendingPathComponent(filename)
        
        // Write to temporary file
        try jsonData.write(to: fileURL)
        
        AppLogger.info(AppLogger.data, "Export file created: \(filename)")
        AppLogger.debug(AppLogger.data, "Workouts: \(workouts.count), Exercises: \(exercises.count), Records: \(personalRecords.count)")
        
        return fileURL
    }
    
    // MARK: - Private Conversion Methods
    
    private static func convertExercise(_ exercise: Exercise) -> [String: Any] {
        [
            "id": exercise.id.uuidString,
            "name": exercise.name,
            "primaryMuscleGroup": exercise.primaryMuscleGroup.rawValue,
            "exerciseType": exercise.exerciseType.rawValue,
            "instructions": exercise.instructions ?? ""
        ]
    }
    
    private static func convertWorkout(_ workout: Workout) -> [String: Any] {
        // Convert workout exercises
        var workoutExercisesData: [[String: Any]] = []
        for workoutExercise in workout.exercises {
            var setsData: [[String: Any]] = []
            for set in workoutExercise.sets {
                setsData.append([
                    "id": set.id.uuidString,
                    "setNumber": set.setNumber,
                    "weight": set.weight,
                    "reps": set.reps,
                    "isCompleted": set.isCompleted,
                    "rpe": set.rpe ?? 0,
                    "restTime": set.restTime ?? 0,
                    "notes": set.notes ?? "",
                    "duration": set.duration ?? 0,
                    "distance": set.distance ?? 0
                ])
            }
            
            workoutExercisesData.append([
                "id": workoutExercise.id.uuidString,
                "order": workoutExercise.order,
                "restTime": workoutExercise.restTime,
                "notes": workoutExercise.notes ?? "",
                "exerciseId": workoutExercise.exercise?.id.uuidString ?? "",
                "sets": setsData
            ])
        }
        
        return [
            "id": workout.id.uuidString,
            "name": workout.name,
            "date": ISO8601DateFormatter().string(from: workout.date),
            "duration": workout.duration ?? 0,
            "notes": workout.notes ?? "",
            "exercises": workoutExercisesData
        ]
    }
    
    private static func convertUserProfile(_ profile: UserProfile) -> [String: Any] {
        [
            "id": profile.id.uuidString,
            "name": profile.name ?? "",
            "weightUnit": profile.weightUnit.rawValue,
            "experienceLevel": profile.experienceLevel.rawValue,
            "workoutDaysPerWeek": profile.workoutDaysPerWeek
        ]
    }
    
    private static func convertPersonalRecord(_ record: PersonalRecord) -> [String: Any] {
        var recordDict: [String: Any] = [
            "id": record.id.uuidString,
            "weight": record.weight,
            "reps": record.reps,
            "date": ISO8601DateFormatter().string(from: record.date),
            "recordType": record.recordType.rawValue
        ]
        
        // Include exercise ID if available
        if let exerciseId = record.exercise?.id {
            recordDict["exerciseId"] = exerciseId.uuidString
        }
        
        return recordDict
    }
    
    private static func convertOneRepMaxHistory(_ history: OneRepMaxHistory) -> [String: Any] {
        var historyDict: [String: Any] = [
            "id": history.id.uuidString,
            "oneRepMax": history.oneRepMax,
            "date": ISO8601DateFormatter().string(from: history.date),
            "source": history.source.rawValue
        ]
        
        // Include exercise ID if available
        if let exerciseId = history.exerciseId {
            historyDict["exerciseId"] = exerciseId.uuidString
        }
        
        // Include confidence level
        switch history.confidence {
        case .high:
            historyDict["confidence"] = "high"
        case .medium:
            historyDict["confidence"] = "medium"
        case .low:
            historyDict["confidence"] = "low"
        }
        
        return historyDict
    }
}
