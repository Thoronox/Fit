import SwiftUI
import SwiftData

/// Centralized preview data provider for all SwiftUI previews
struct PreviewData {
    let container: ModelContainer
    let exercises: [Exercise]
    let workouts: [Workout]
    let personalRecords: [PersonalRecord]
    let oneRepMaxHistories: [OneRepMaxHistory]
    let userProfile: UserProfile
    
    @MainActor
    static func create() -> PreviewData {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try! ModelContainer(
            for: Workout.self, Exercise.self, PersonalRecord.self, 
            OneRepMaxHistory.self, UserProfile.self,
            configurations: config
        )
        
        let calendar = Calendar.current
        let today = Date()
        
        // MARK: - Create Exercises
        
        let benchPress = Exercise(
            id: UUID().uuidString,
            name: "Barbell Bench Press",
            primaryMuscleGroup: .chest,
            exerciseType: .strength
        )
        benchPress.equipment = .barbell
        benchPress.secondaryMuscleGroups = [.triceps, .shoulders]
        benchPress.instructions = "Lie on a flat bench with your feet flat on the floor. Grip the barbell slightly wider than shoulder-width. Lower the bar to your chest in a controlled manner, then press it back up to the starting position."
        benchPress.isCompound = true
        
        let pullup = Exercise(
            id: UUID().uuidString,
            name: "Pull-up",
            primaryMuscleGroup: .back,
            exerciseType: .strength
        )
        pullup.equipment = .pullupBar
        pullup.secondaryMuscleGroups = [.biceps]
        pullup.instructions = "Hang from a pull-up bar with arms fully extended and hands slightly wider than shoulder-width apart. Pull your body up until your chin is over the bar. Lower yourself back down with control to full arm extension."
        pullup.isCompound = true
        
        let squat = Exercise(
            id: UUID().uuidString,
            name: "Barbell Squat",
            primaryMuscleGroup: .quadriceps,
            exerciseType: .strength
        )
        squat.equipment = .barbell
        squat.secondaryMuscleGroups = [.glutes, .hamstrings]
        squat.instructions = "Stand with feet shoulder-width apart. Position the barbell on your upper back. Lower your body by bending your knees and hips, keeping your back straight. Descend until thighs are parallel to the floor, then push back up."
        squat.isCompound = true
        
        let deadlift = Exercise(
            id: UUID().uuidString,
            name: "Deadlift",
            primaryMuscleGroup: .back,
            exerciseType: .strength
        )
        deadlift.equipment = .barbell
        deadlift.secondaryMuscleGroups = [.glutes, .hamstrings]
        deadlift.instructions = "Stand with feet hip-width apart, barbell over mid-foot. Bend at hips and knees to grip the bar. Keep your back straight and lift the bar by extending your hips and knees. Lower with control."
        deadlift.isCompound = true
        
        let exercises = [benchPress, pullup, squat, deadlift]
        exercises.forEach { container.mainContext.insert($0) }
        
        // MARK: - Create Workouts with Sets
        
        let workout1 = Workout(name: "Push Day", date: calendar.date(byAdding: .day, value: -7, to: today)!)
        workout1.duration = 3600
        workout1.notes = "Great session, feeling strong"
        
        let we1 = WorkoutExercise(exercise: benchPress, order: 0)
        we1.restTime = 90
        let set1_1 = ExerciseSet(setNumber: 1, weight: 80.0, reps: 10)
        set1_1.isCompleted = true
        let set1_2 = ExerciseSet(setNumber: 2, weight: 85.0, reps: 8)
        set1_2.isCompleted = true
        let set1_3 = ExerciseSet(setNumber: 3, weight: 85.0, reps: 8)
        set1_3.isCompleted = true
        we1.sets = [set1_1, set1_2, set1_3]
        workout1.exercises.append(we1)
        
        let workout2 = Workout(name: "Pull Day", date: calendar.date(byAdding: .day, value: -5, to: today)!)
        workout2.duration = 3300
        
        let we2 = WorkoutExercise(exercise: pullup, order: 0)
        we2.restTime = 120
        let set2_1 = ExerciseSet(setNumber: 1, weight: 0.0, reps: 12)
        set2_1.isCompleted = true
        let set2_2 = ExerciseSet(setNumber: 2, weight: 0.0, reps: 10)
        set2_2.isCompleted = true
        let set2_3 = ExerciseSet(setNumber: 3, weight: 0.0, reps: 8)
        set2_3.isCompleted = true
        we2.sets = [set2_1, set2_2, set2_3]
        workout2.exercises.append(we2)
        
        let workout3 = Workout(name: "Leg Day", date: calendar.date(byAdding: .day, value: -2, to: today)!)
        workout3.duration = 4200
        
        let we3 = WorkoutExercise(exercise: squat, order: 0)
        we3.restTime = 180
        let set3_1 = ExerciseSet(setNumber: 1, weight: 100.0, reps: 12)
        set3_1.isCompleted = true
        let set3_2 = ExerciseSet(setNumber: 2, weight: 100.0, reps: 12)
        set3_2.isCompleted = true
        let set3_3 = ExerciseSet(setNumber: 3, weight: 100.0, reps: 10)
        set3_3.isCompleted = true
        we3.sets = [set3_1, set3_2, set3_3]
        workout3.exercises.append(we3)
        
        // MARK: - Create Active Workout (for StartWorkoutView preview)
        
        let activeWorkout = Workout(name: "Upper Body", date: today)
        activeWorkout.duration = 0 // Still in progress
        
        // Bench Press - partially completed
        let we4 = WorkoutExercise(exercise: benchPress, order: 0)
        we4.restTime = 90
        let set4_1 = ExerciseSet(setNumber: 1, weight: 80.0, reps: 10)
        set4_1.isCompleted = true
        let set4_2 = ExerciseSet(setNumber: 2, weight: 85.0, reps: 8)
        set4_2.isCompleted = true
        let set4_3 = ExerciseSet(setNumber: 3, weight: 85.0, reps: 8)
        set4_3.isCompleted = false // Not completed yet
        let set4_4 = ExerciseSet(setNumber: 4, weight: 85.0, reps: 8)
        set4_4.isCompleted = false // Not completed yet
        we4.sets = [set4_1, set4_2, set4_3, set4_4]
        activeWorkout.exercises.append(we4)
        
        // Pull-ups - not started
        let we5 = WorkoutExercise(exercise: pullup, order: 1)
        we5.restTime = 120
        let set5_1 = ExerciseSet(setNumber: 1, weight: 0.0, reps: 12)
        set5_1.isCompleted = false
        let set5_2 = ExerciseSet(setNumber: 2, weight: 0.0, reps: 10)
        set5_2.isCompleted = false
        let set5_3 = ExerciseSet(setNumber: 3, weight: 0.0, reps: 10)
        set5_3.isCompleted = false
        we5.sets = [set5_1, set5_2, set5_3]
        activeWorkout.exercises.append(we5)
        
        // Deadlift - not started
        let we6 = WorkoutExercise(exercise: deadlift, order: 2)
        we6.restTime = 180
        let set6_1 = ExerciseSet(setNumber: 1, weight: 120.0, reps: 5)
        set6_1.isCompleted = false
        let set6_2 = ExerciseSet(setNumber: 2, weight: 130.0, reps: 3)
        set6_2.isCompleted = false
        let set6_3 = ExerciseSet(setNumber: 3, weight: 140.0, reps: 1)
        set6_3.isCompleted = false
        we6.sets = [set6_1, set6_2, set6_3]
        activeWorkout.exercises.append(we6)
        
        let workouts = [workout1, workout2, workout3, activeWorkout]
        workouts.forEach { container.mainContext.insert($0) }
        
        // MARK: - Create Personal Records
        
        let pr1 = PersonalRecord(
            exercise: benchPress,
            weight: 85.0,
            reps: 8,
            date: calendar.date(byAdding: .day, value: -7, to: today)!,
            recordType: .actual
        )
        
        let pr2 = PersonalRecord(
            exercise: pullup,
            weight: 0.0,
            reps: 12,
            date: calendar.date(byAdding: .day, value: -5, to: today)!,
            recordType: .actual
        )
        
        let pr3 = PersonalRecord(
            exercise: squat,
            weight: 100.0,
            reps: 12,
            date: calendar.date(byAdding: .day, value: -2, to: today)!,
            recordType: .calculated
        )
        
        let pr4 = PersonalRecord(
            exercise: deadlift,
            weight: 140.0,
            reps: 5,
            date: calendar.date(byAdding: .day, value: -10, to: today)!,
            recordType: .actual
        )
        
        let personalRecords = [pr1, pr2, pr3, pr4]
        personalRecords.forEach { container.mainContext.insert($0) }
        
        // MARK: - Create OneRepMax History
        
        let history1 = OneRepMaxHistory(
            exercise: benchPress,
            oneRepMax: 80.0,
            date: calendar.date(byAdding: .day, value: -14, to: today)!,
            source: .calculatedFromSet
        )
        
        let history2 = OneRepMaxHistory(
            exercise: benchPress,
            oneRepMax: 85.0,
            date: calendar.date(byAdding: .day, value: -10, to: today)!,
            source: .calculatedFromSet
        )
        
        let history3 = OneRepMaxHistory(
            exercise: benchPress,
            oneRepMax: 82.0,
            date: calendar.date(byAdding: .day, value: -7, to: today)!,
            source: .calculatedFromSet
        )
        
        let history4 = OneRepMaxHistory(
            exercise: benchPress,
            oneRepMax: 90.0,
            date: calendar.date(byAdding: .day, value: -3, to: today)!,
            source: .calculatedFromSet
        )
        
        let history5 = OneRepMaxHistory(
            exercise: benchPress,
            oneRepMax: 92.0,
            date: today,
            source: .calculatedFromSet
        )
        
        let history6 = OneRepMaxHistory(
            exercise: squat,
            oneRepMax: 135.0,
            date: calendar.date(byAdding: .day, value: -10, to: today)!,
            source: .calculatedFromSet
        )
        
        let history7 = OneRepMaxHistory(
            exercise: squat,
            oneRepMax: 140.0,
            date: calendar.date(byAdding: .day, value: -2, to: today)!,
            source: .calculatedFromSet
        )
        
        let oneRepMaxHistories = [history1, history2, history3, history4, history5, history6, history7]
        oneRepMaxHistories.forEach { container.mainContext.insert($0) }
        
        // MARK: - Create User Profile
        // Create sample user profile
        let userProfile = UserProfile()
        userProfile.name = "John Doe"
        container.mainContext.insert(userProfile)
        
        return PreviewData(
            container: container,
            exercises: exercises,
            workouts: workouts,
            personalRecords: personalRecords,
            oneRepMaxHistories: oneRepMaxHistories,
            userProfile: userProfile
        )
    }
}
