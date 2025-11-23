import Foundation
import SwiftData

/// Service responsible for restoring data models from dictionaries
struct DataRestoreService {
    
    // MARK: - Exercise Restoration
    
    static func restoreExercise(from dict: [String: Any]) -> Exercise? {
        guard let name = dict["name"] as? String,
              let muscleGroupRaw = dict["primaryMuscleGroup"] as? String,
              let muscleGroup = MuscleGroup(rawValue: muscleGroupRaw),
              let typeRaw = dict["exerciseType"] as? String,
              let exerciseType = ExerciseType(rawValue: typeRaw) else {
            AppLogger.debug(AppLogger.data, "Failed to restore exercise from dict")
            return nil
        }
        
        let exercise = Exercise(
            id: (dict["id"] as? String) ?? UUID().uuidString,
            name: name,
            primaryMuscleGroup: muscleGroup,
            exerciseType: exerciseType
        )
        
        if let instructions = dict["instructions"] as? String {
            exercise.instructions = instructions
        }
        
        return exercise
    }
    
    // MARK: - Workout Restoration
    
    static func restoreWorkout(from dict: [String: Any], exerciseLookup: [String: Exercise]) -> Workout? {
        guard let name = dict["name"] as? String else { return nil }
        
        let workout = Workout(name: name)
        
        if let dateString = dict["date"] as? String,
           let date = ISO8601DateFormatter().date(from: dateString) {
            workout.date = date
        }
        
        if let duration = dict["duration"] as? TimeInterval {
            workout.duration = duration
        }
        
        if let notes = dict["notes"] as? String {
            workout.notes = notes
        }
        
        // Restore workout exercises
        if let exercisesData = dict["exercises"] as? [[String: Any]] {
            for exerciseDict in exercisesData {
                if let workoutExercise = restoreWorkoutExercise(from: exerciseDict, exerciseLookup: exerciseLookup) {
                    workoutExercise.workout = workout
                    workout.exercises.append(workoutExercise)
                }
            }
        }
        
        return workout
    }
    
    // MARK: - Workout Exercise Restoration
    
    static func restoreWorkoutExercise(from dict: [String: Any], exerciseLookup: [String: Exercise]) -> WorkoutExercise? {
        guard let order = dict["order"] as? Int else { return nil }
        
        // Look up the exercise
        var exercise: Exercise?
        if let exerciseIdString = dict["exerciseId"] as? String {
            exercise = exerciseLookup[exerciseIdString]
        }
        
        guard let validExercise = exercise else {
            AppLogger.warning(AppLogger.data, "Skipping workout exercise - exercise not found")
            return nil
        }
        
        let workoutExercise = WorkoutExercise(exercise: validExercise, order: order)
        
        if let restTime = dict["restTime"] as? Int {
            workoutExercise.restTime = restTime
        }
        
        if let notes = dict["notes"] as? String {
            workoutExercise.notes = notes
        }
        
        // Restore sets
        if let setsData = dict["sets"] as? [[String: Any]] {
            for setDict in setsData {
                if let set = restoreExerciseSet(from: setDict) {
                    set.workoutExercise = workoutExercise
                    workoutExercise.sets.append(set)
                }
            }
        }
        
        return workoutExercise
    }
    
    // MARK: - Exercise Set Restoration
    
    static func restoreExerciseSet(from dict: [String: Any]) -> ExerciseSet? {
        guard let setNumber = dict["setNumber"] as? Int,
              let weight = dict["weight"] as? Double,
              let reps = dict["reps"] as? Int else { return nil }
        
        let set = ExerciseSet(setNumber: setNumber, weight: weight, reps: reps)
        
        if let isCompleted = dict["isCompleted"] as? Bool {
            set.isCompleted = isCompleted
        }
        
        if let rpe = dict["rpe"] as? Double, rpe > 0 {
            set.rpe = rpe
        }
        
        if let restTime = dict["restTime"] as? Int, restTime > 0 {
            set.restTime = restTime
        }
        
        if let notes = dict["notes"] as? String, !notes.isEmpty {
            set.notes = notes
        }
        
        if let duration = dict["duration"] as? TimeInterval, duration > 0 {
            set.duration = duration
        }
        
        if let distance = dict["distance"] as? Double, distance > 0 {
            set.distance = distance
        }
        
        return set
    }
    
    // MARK: - User Profile Restoration
    
    static func restoreUserProfile(from dict: [String: Any]) -> UserProfile? {
        let profile = UserProfile()
        
        if let name = dict["name"] as? String {
            profile.name = name
        }
        
        if let weightUnitRaw = dict["weightUnit"] as? String,
           let weightUnit = WeightUnit(rawValue: weightUnitRaw) {
            profile.weightUnit = weightUnit
        }
        
        if let experienceLevelRaw = dict["experienceLevel"] as? String,
           let experienceLevel = ExperienceLevel(rawValue: experienceLevelRaw) {
            profile.experienceLevel = experienceLevel
        }
        
        if let workoutDays = dict["workoutDaysPerWeek"] as? Int {
            profile.workoutDaysPerWeek = workoutDays
        }
        
        return profile
    }
    
    // MARK: - Personal Record Restoration
    
    static func restorePersonalRecord(from dict: [String: Any], exerciseLookup: [String: Exercise]) -> PersonalRecord? {
        guard let weight = dict["weight"] as? Double,
              let reps = dict["reps"] as? Int else { return nil }
        
        let recordTypeRaw = dict["recordType"] as? String ?? "calculated"
        let recordType = RecordType(rawValue: recordTypeRaw) ?? .calculated
        
        // Look up the exercise by ID from the lookup dictionary
        var exercise: Exercise?
        if let exerciseIdString = dict["exerciseId"] as? String {
            exercise = exerciseLookup[exerciseIdString]
        }
        
        // If we can't find the exercise, skip this record
        guard let validExercise = exercise else {
            AppLogger.warning(AppLogger.data, "Skipping personal record - exercise not found")
            return nil
        }
        
        let record = PersonalRecord(
            exercise: validExercise,
            weight: weight,
            reps: reps,
            recordType: recordType
        )
        
        if let dateString = dict["date"] as? String,
           let date = ISO8601DateFormatter().date(from: dateString) {
            record.date = date
        }
        
        return record
    }
    
    // MARK: - One Rep Max History Restoration
    
    static func restoreOneRepMaxHistory(from dict: [String: Any], exerciseLookup: [String: Exercise]) -> OneRepMaxHistory? {
        guard let oneRepMax = dict["oneRepMax"] as? Double else { return nil }
        
        // Look up the exercise by ID from the lookup dictionary
        var exercise: Exercise?
        if let exerciseIdString = dict["exerciseId"] as? String {
            exercise = exerciseLookup[exerciseIdString]
        }
        
        // If we can't find the exercise, skip this history entry
        guard let validExercise = exercise else {
            AppLogger.warning(AppLogger.data, "Skipping 1RM history - exercise not found")
            return nil
        }
        
        let sourceRaw = dict["source"] as? String ?? "calculatedFromSet"
        let source = OneRepMaxSource(rawValue: sourceRaw) ?? .calculatedFromSet
        
        let history = OneRepMaxHistory(
            exercise: validExercise,
            oneRepMax: oneRepMax,
            source: source
        )
        
        if let dateString = dict["date"] as? String,
           let date = ISO8601DateFormatter().date(from: dateString) {
            history.date = date
        }
        
        if let confidenceLevelRaw = dict["confidence"] as? String,
           let confidenceLevel = ConfidenceLevel(rawValue: confidenceLevelRaw) {
            history.confidence = confidenceLevel
        }
        
        return history
    }
}
