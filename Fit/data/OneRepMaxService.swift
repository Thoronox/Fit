import Foundation
import SwiftData

class OneRepMaxService {
    private let modelContext: ModelContext
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    // Get 1RM history for an exercise
    func getOneRepMaxHistory(for exercise: Exercise) -> [OneRepMaxHistory] {
        do {
            // Fetch all OneRepMaxHistory records using basic FetchDescriptor
            let allRecords = try modelContext.fetch(FetchDescriptor<OneRepMaxHistory>())
            
            // Filter for the specific exercise and sort by date (most recent first)
            let exerciseHistory = allRecords
                .filter { $0.exerciseId == exercise.id }
                .sorted { $0.date > $1.date }
            
            return exerciseHistory
            
        } catch {
            print("Error fetching one rep max history: \(error)")
            return []
        }
    }


    func getCurrentOneRepMaxByExerciseName(_ exerciseName: String) -> OneRepMaxHistory? {
        do {
            AppLogger.debug(AppLogger.oneRepMax, "Fetching current 1RM for exercise: \(exerciseName)")
            
            // Fetch all exercises
            let allExercises = try modelContext.fetch(FetchDescriptor<Exercise>())
            
            // Find the exercise with the specified name
            guard let exercise = allExercises.first(where: { $0.name.lowercased() == exerciseName.lowercased() }) else {
                AppLogger.warning(AppLogger.oneRepMax, "Exercise '\(exerciseName)' not found in database")
                return nil
            }
            
            // Fetch all OneRepMaxHistory records
            let allRecords = try modelContext.fetch(FetchDescriptor<OneRepMaxHistory>())
            
            // Filter for this exercise and get the most recent
            let exerciseRecords = allRecords
                .filter { $0.exerciseId == exercise.id }
                .sorted { $0.date > $1.date }
            
            if let latestRecord = exerciseRecords.first {
                AppLogger.debug(AppLogger.oneRepMax, "Current 1RM for \(exerciseName): \(latestRecord.oneRepMax)kg")
            }
            
            return exerciseRecords.first
            
        } catch {
            AppLogger.error(AppLogger.oneRepMax, "Failed to fetch 1RM for exercise: \(exerciseName)", error: error)
            return nil
        }
    }

    // Auto-update 1RM when a new PR is achieved
    func updateOneRepMaxFromSet(_ set: ExerciseSet) {
        guard let exercise = set.workoutExercise?.exercise else { return }
        
        // Check if this set represents a new PR
        let currentPR = getCurrentOneRepMaxByExerciseName(exercise.name)
        
        let newOneRepMax = set.oneRepMax()
        
        if currentPR?.oneRepMax ?? 0 < newOneRepMax {
            // Create new 1RM history entry
            let history = OneRepMaxHistory(
                exercise: exercise,
                oneRepMax: newOneRepMax,
                source: .calculatedFromSet,
                calculationMethod: .epley
            )
            history.confidence = set.oneRepMaxQuality
            
            // Create PersonalRecord
            let pr = PersonalRecord(
                exercise: exercise,
                weight: set.weight,
                reps: set.reps,
                recordType: .calculated
            )
            pr.workoutExercise = set.workoutExercise
            history.sourceRecord = pr
            
            modelContext.insert(history)
            modelContext.insert(pr)
        }
    }
    
    // Calculate 1RM progression over time
    func getProgressionData(for exercise: Exercise, timeRange: TimeRange = .all) -> [OneRepMaxDataPoint] {
        let history = getOneRepMaxHistory(for: exercise)
        let filteredHistory = filterByTimeRange(history, timeRange: timeRange)
        
        return filteredHistory.map { record in
            OneRepMaxDataPoint(
                date: record.date,
                oneRepMax: record.oneRepMax,
                confidence: record.confidence.doubleValue,
                source: record.source
            )
        }
    }
    
    private func filterByTimeRange(_ history: [OneRepMaxHistory], timeRange: TimeRange) -> [OneRepMaxHistory] {
        let cutoffDate: Date
        let now = Date()
        
        switch timeRange {
        case .lastMonth:
            cutoffDate = Calendar.current.date(byAdding: .month, value: -1, to: now) ?? now
        case .lastThreeMonths:
            cutoffDate = Calendar.current.date(byAdding: .month, value: -3, to: now) ?? now
        case .lastSixMonths:
            cutoffDate = Calendar.current.date(byAdding: .month, value: -6, to: now) ?? now
        case .lastYear:
            cutoffDate = Calendar.current.date(byAdding: .year, value: -1, to: now) ?? now
        case .all:
            return history
        }
        
        return history.filter { $0.date >= cutoffDate }
    }
}
