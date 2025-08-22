import SwiftData
import Foundation

// MARK: - Data Structures for Workout History

struct WorkoutHistoryItem {
    let workoutId: UUID
    let workoutName: String
    let workoutDate: Date
    let exercises: [ExerciseHistoryItem]
    let totalVolume: Double
    let totalSets: Int
    let duration: TimeInterval?
}

struct ExerciseHistoryItem {
    let exerciseName: String
    let exerciseId: UUID
    let primaryMuscleGroup: MuscleGroup
    let sets: [SetHistoryItem]
    let totalVolume: Double
    let maxWeight: Double
    let oneRepMax: Double
}

struct SetHistoryItem {
    let setNumber: Int
    let weight: Double
    let reps: Int
    let isCompleted: Bool
    let volume: Double
    let oneRepMax: Double
    let rpe: Double?
}

// MARK: - Main Function

func getLast10WorkoutsHistory(from context: ModelContext) -> [WorkoutHistoryItem] {
    do {
        // Create a fetch descriptor to get the last 10 workouts, sorted by date (newest first)
        let fetchDescriptor = FetchDescriptor<Workout>(
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        
        // Fetch all workouts first, then take the first 10
        let allWorkouts = try context.fetch(fetchDescriptor)
        let last10Workouts = Array(allWorkouts.prefix(10))
        
        // Convert to WorkoutHistoryItem structures
        let workoutHistory: [WorkoutHistoryItem] = last10Workouts.map { workout in
            
            // Process exercises for this workout
            let exerciseHistory: [ExerciseHistoryItem] = workout.exercises
                .sorted(by: { $0.order < $1.order }) // Sort by exercise order in workout
                .compactMap { workoutExercise in
                    guard let exercise = workoutExercise.exercise else { return nil }
                    
                    // Process sets for this exercise
                    let setHistory: [SetHistoryItem] = workoutExercise.sets
                        .sorted(by: { $0.setNumber < $1.setNumber }) // Sort by set number
                        .map { exerciseSet in
                            SetHistoryItem(
                                setNumber: exerciseSet.setNumber,
                                weight: exerciseSet.weight,
                                reps: exerciseSet.reps,
                                isCompleted: exerciseSet.isCompleted,
                                volume: exerciseSet.volume,
                                oneRepMax: exerciseSet.oneRepMax,
                                rpe: exerciseSet.rpe
                            )
                        }
                    
                    return ExerciseHistoryItem(
                        exerciseName: exercise.name,
                        exerciseId: exercise.id,
                        primaryMuscleGroup: exercise.primaryMuscleGroup,
                        sets: setHistory,
                        totalVolume: workoutExercise.totalVolume,
                        maxWeight: workoutExercise.maxWeight,
                        oneRepMax: workoutExercise.oneRepMax
                    )
                }
            
            return WorkoutHistoryItem(
                workoutId: workout.id,
                workoutName: workout.name,
                workoutDate: workout.date,
                exercises: exerciseHistory,
                totalVolume: workout.totalVolume,
                totalSets: workout.totalSets,
                duration: workout.duration
            )
        }
        
        return workoutHistory
        
    } catch {
        print("Error fetching workout history: \(error)")
        return []
    }
}

// MARK: - Helper Functions for AI Context

func formatWorkoutHistoryForAI(_ workoutHistory: [WorkoutHistoryItem]) -> String {
    guard !workoutHistory.isEmpty else {
        return "No workout history available."
    }
    
    let dateFormatter = DateFormatter()
    dateFormatter.dateStyle = .medium
    dateFormatter.timeStyle = .none
    
    var output = "WORKOUT HISTORY (Last \(workoutHistory.count) workouts):\n\n"
    
    for (index, workout) in workoutHistory.enumerated() {
        output += "=== WORKOUT \(index + 1) ===\n"
        output += "Name: \(workout.workoutName)\n"
        output += "Date: \(dateFormatter.string(from: workout.workoutDate))\n"
        output += "Total Volume: \(String(format: "%.1f", workout.totalVolume)) kg\n"
        output += "Total Sets: \(workout.totalSets)\n"
        
        if let duration = workout.duration {
            let minutes = Int(duration / 60)
            output += "Duration: \(minutes) minutes\n"
        }
        
        output += "\nExercises:\n"
        
        for exercise in workout.exercises {
            output += "  • \(exercise.exerciseName)\n"
            output += "    Sets: \(exercise.sets.count), Total Volume: \(String(format: "%.1f", exercise.totalVolume)) kg\n"
            output += "    Max Weight: \(String(format: "%.1f", exercise.maxWeight)) kg, Estimated 1RM: \(String(format: "%.1f", exercise.oneRepMax)) kg\n"
            
            // Show individual sets
            for set in exercise.sets where set.isCompleted {
                let rpeText = set.rpe != nil ? ", RPE: \(String(format: "%.1f", set.rpe!))" : ""
                output += "      Set \(set.setNumber): \(String(format: "%.1f", set.weight)) kg × \(set.reps) reps\(rpeText)\n"
            }
            output += "\n"
        }
        
        output += "\n"
    }
    
    return output
}

// MARK: - Usage Example Function

func getWorkoutHistoryForAI(from context: ModelContext) -> String {
    let workoutHistory = getLast10WorkoutsHistory(from: context)
    return formatWorkoutHistoryForAI(workoutHistory)
}

