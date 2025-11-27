import Foundation
import SwiftData

// MARK: - Core Data Models

@Model
class Workout {
    var id: UUID
    var name: String
    var date: Date
    var duration: TimeInterval? // in seconds
    var notes: String?
    
    // Relationships
    @Relationship(deleteRule: .cascade, inverse: \WorkoutExercise.workout)
    var exercises: [WorkoutExercise] = []
    
    init(name: String, date: Date = Date()) {
        self.id = UUID()
        self.name = name
        self.date = date
    }
    
    // Computed properties
    var totalVolume: Double {
        exercises.reduce(0) { $0 + $1.totalVolume }
    }
    
    var totalSets: Int {
        exercises.reduce(0) { $0 + $1.sets.count }
    }
}

@Model
class Exercise {
    var id: UUID
    var name: String
    var instructions: String?
    var primaryMuscleGroup: MuscleGroup
    var secondaryMuscleGroups: [MuscleGroup] = []
    var equipment: Equipment?
    var exerciseType: ExerciseType
    var isCompound: Bool // Whether it's a compound movement
    
    init(id: String, name: String, primaryMuscleGroup: MuscleGroup, exerciseType: ExerciseType) {
        // self.id = UUID()
        self.id = UUID(uuidString: id)!
        self.name = name
        self.primaryMuscleGroup = primaryMuscleGroup
        self.exerciseType = exerciseType
        self.isCompound = false
    }
    
    var debugInfo: String {
        "Name: \(name), PrimaryMuscleGroup: \(primaryMuscleGroup), ID: \(id)"
    }
}

@Model
class WorkoutExercise {
    var id: UUID
    var order: Int // Order within the workout
    var restTime: Int // Rest time after this exercise
    var notes: String?
    
    // Relationships
    var workout: Workout?
    var exercise: Exercise?
    
    @Relationship(deleteRule: .cascade, inverse: \ExerciseSet.workoutExercise)
    var sets: [ExerciseSet] = []
    
    init(exercise: Exercise, order: Int) {
        self.id = UUID()
        self.exercise = exercise
        self.order = order
        self.restTime = 60
    }
    
    // Computed properties
    var totalVolume: Double {
        sets.reduce(0) { $0 + $1.volume }
    }
    
    var maxWeight: Double {
        sets.compactMap { $0.weight }.max() ?? 0
    }
    
    var oneRepMax: Double {
        sets.compactMap { $0.oneRepMax }.max() ?? 0
    }
}

@Model
class ExerciseSet: Identifiable {
    var id: UUID
    var setNumber: Int
    var weight: Double // in kg or lbs
    var reps: Int
    var isCompleted: Bool
    var rpe: Double? // Rate of Perceived Exertion (1-10)
    var restTime: Int? // Actual rest time taken
    var notes: String?
    
    // For time-based exercises
    var duration: TimeInterval? // in seconds
    
    // For distance-based exercises
    var distance: Double? // in meters
    
    // Relationship
    var workoutExercise: WorkoutExercise?
    
    init(setNumber: Int, weight: Double, reps: Int) {
        self.id = UUID()
        self.setNumber = setNumber
        self.weight = weight
        self.reps = reps
        self.isCompleted = false
    }
    
    // Computed properties
    var volume: Double {
        weight * Double(reps)
    }
    
    var oneRepMax: Double {
        // Epley formula: 1RM = weight * (1 + reps/30)
        weight * (1 + Double(reps) / 30)
    }
    
    // Enhanced 1RM calculation with different methods
    func oneRepMax(using method: OneRepMaxCalculation = .epley) -> Double {
        method.calculate(weight: weight, reps: reps)
    }
    
    // Determine if this set is a potential PR
    var isPotentialPR: Bool {
        guard let _ = workoutExercise?.exercise else { return false }
        // Logic to check if this is better than previous records
        // This would need access to ModelContext to query existing records
        return true // Simplified for example
    }
    
    // Quality score for 1RM estimation (lower reps = higher quality for strength)
    var oneRepMaxQuality: ConfidenceLevel {
        switch reps {
        case 1: return .high
        case 2...5: return .medium
        case 6...12: return .medium
        default: return .low
        }
    }
}

// MARK: - Enums and Supporting Types

enum MuscleGroup: String, CaseIterable, Codable {
    case chest = "Chest"
    case back = "Back"
    case shoulders = "Shoulders"
    case biceps = "Biceps"
    case triceps = "Triceps"
    case forearms = "Forearms"
    case abs = "Abs"
    case obliques = "Obliques"
    case quadriceps = "Quadriceps"
    case hamstrings = "Hamstrings"
    case glutes = "Glutes"
    case calves = "Calves"
    case cardio = "Cardio"
    case fullBody = "Full Body"
}

enum Equipment: String, CaseIterable, Codable {
    case barbell = "Barbell"
    case dumbbell = "Dumbbells"
    case kettlebell = "Kettlebell"
    case cableStation = "Cable Station"
    case pullupBar = "Pull-up Bar"
    case dipStation = "Dip Station"
    case smithMachine = "Smith Machine"
    case legPress = "Leg Press"
    case latPulldown = "Lat Pulldown"
    case chestPress = "Chest Press"
    case rowingMachine = "Rowing Machine"
    case treadmill = "Treadmill"
    case bike = "Exercise Bike"
    case resistanceBand = "Resistance Band"
    case medicineBall = "Medicine Ball"
    case bodyweight = "Bodyweight"
    case none = "None"
}

enum ExerciseType: String, CaseIterable, Codable {
    case strength = "Strength"
    case cardio = "Cardio"
    case flexibility = "Flexibility"
    case plyometric = "Plyometric"
    case powerlifting = "Powerlifting"
    case olympic = "Olympic Lifting"
}

// MARK: - Progress Tracking

@Model
class PersonalRecord {
    var id: UUID
    var exercise: Exercise?
    var weight: Double
    var reps: Int
    var date: Date
    var workoutExercise: WorkoutExercise?
    var recordType: RecordType
    var calculationMethod: OneRepMaxCalculation
    
    init(exercise: Exercise, weight: Double, reps: Int, date: Date = Date(), recordType: RecordType = .calculated) {
        self.id = UUID()
        self.exercise = exercise
        self.weight = weight
        self.reps = reps
        self.date = date
        self.recordType = recordType
        self.calculationMethod = .epley
    }
    
    var oneRepMax: Double {
        calculationMethod.calculate(weight: weight, reps: reps)
    }
}

enum RecordType: String, CaseIterable, Codable {
    case actual = "Actual" // True 1RM attempt
    case calculated = "Calculated" // Based on rep performance
}

enum OneRepMaxCalculation: String, CaseIterable, Codable {
    case epley = "Epley"
    case brzycki = "Brzycki"
    case lombardi = "Lombardi"
    case mcglothin = "McGlothin"
    
    func calculate(weight: Double, reps: Int) -> Double {
        switch self {
        case .epley:
            return weight * (1 + Double(reps) / 30)
        case .brzycki:
            return weight * (36 / (37 - Double(reps)))
        case .lombardi:
            return weight * pow(Double(reps), 0.10)
        case .mcglothin:
            return (100 * weight) / (101.3 - 2.67123 * Double(reps))
        }
    }
}


@Model
class OneRepMaxHistory {
    var id: UUID
    var exerciseId: UUID? { exercise?.id }
    var exercise: Exercise?
    var oneRepMax: Double
    var date: Date
    var source: OneRepMaxSource
    var sourceRecord: PersonalRecord? // Link to the PR that generated this 1RM
    var calculationMethod: OneRepMaxCalculation
    var confidence: ConfidenceLevel // How reliable this 1RM estimate is
    
    init(exercise: Exercise, oneRepMax: Double, date: Date = Date(), source: OneRepMaxSource, calculationMethod: OneRepMaxCalculation = .epley) {
        self.id = UUID()
        self.exercise = exercise
        self.oneRepMax = oneRepMax
        self.date = date
        self.source = source
        self.calculationMethod = calculationMethod
        self.confidence = source.defaultConfidence
    }
}

    
    
enum OneRepMaxSource: String, CaseIterable, Codable {
    case actualTest = "Actual 1RM Test"
    case calculatedFromSet = "Calculated from Set"
    case estimatedFromVolume = "Estimated from Volume"
    case manualEntry = "Manual Entry"
    
    var defaultConfidence: ConfidenceLevel {
        switch self {
        case .actualTest: return .high
        case .calculatedFromSet: return .medium
        case .estimatedFromVolume: return .low
        case .manualEntry: return .medium
        }
    }
}

enum ConfidenceLevel: String, CaseIterable, Codable {
    case high = "High"
    case medium = "Medium"
    case low = "Low"
    
    var doubleValue: Double {
        switch self {
        case .low:
            return 0.3
        case .medium:
            return 0.6
        case .high:
            return 1.0
        // Add other cases as needed based on your ConfidenceLevel definition
        }
    }
}


// MARK: - TimeRange Enum
enum TimeRange: String, CaseIterable {
    case lastMonth = "Last Month"
    case lastThreeMonths = "Last 3 Months"
    case lastSixMonths = "Last 6 Months"
    case lastYear = "Last Year"
    case all = "All Time"
    
    var displayName: String {
        return self.rawValue
    }
}

// MARK: - OneRepMaxDataPoint Struct
struct OneRepMaxDataPoint {
    let date: Date
    let oneRepMax: Double
    let confidence: Double
    let source: OneRepMaxSource
    
    init(date: Date, oneRepMax: Double, confidence: Double = 1.0, source: OneRepMaxSource) {
        self.date = date
        self.oneRepMax = oneRepMax
        self.confidence = confidence
        self.source = source
    }
}
    
// MARK: - User Preferences and Settings
 
@Model
class UserProfile {
    var id: UUID
    var name: String?
    var weightUnit: WeightUnit
    var experienceLevel: ExperienceLevel
    var primaryGoals: [FitnessGoal] = []
    var availableEquipment: [Equipment] = []
    var workoutDaysPerWeek: Int
    
    init() {
        self.id = UUID()
        self.weightUnit = .kg
        self.experienceLevel = .beginner
        self.workoutDaysPerWeek = 3
    }
    
    var preferredOneRepMaxCalculation: OneRepMaxCalculation {
        get {
            // Could store this as a property, defaulting to Epley
            return .epley
        }
    }
    
    var autoTrackOneRepMax: Bool {
        get {
            // Could store this as a property, defaulting to true
            return true
        }
    }
}

enum WeightUnit: String, CaseIterable, Codable {
    case kg = "kg"
    case lbs = "lbs"
}

enum ExperienceLevel: String, CaseIterable, Codable {
    case beginner = "Beginner"
    case intermediate = "Intermediate"
    case advanced = "Advanced"
}

enum FitnessGoal: String, CaseIterable, Codable {
    case buildMuscle = "Build Muscle"
    case loseWeight = "Lose Weight"
    case increaseStrength = "Increase Strength"
    case improveEndurance = "Improve Endurance"
    case generalFitness = "General Fitness"
    case powerlifting = "Powerlifting"
    case bodybuilding = "Bodybuilding"
}







extension WorkoutExercise {
    
    /// Debug method to find all workout exercises for this exercise across all workouts
    func findAllPerformances(in context: ModelContext) -> [WorkoutExercise] {
        guard let currentExercise = self.exercise else {
            print("❌ No exercise assigned to this WorkoutExercise")
            return []
        }
        
        print("🔍 Searching for exercise: \(currentExercise.name) with ID: \(currentExercise.id)")
        
        // First, let's get ALL WorkoutExercises to see what we have
        let allDescriptor = FetchDescriptor<WorkoutExercise>()
        
        do {
            let allWorkoutExercises = try context.fetch(allDescriptor)
            print("📊 Total WorkoutExercises in database: \(allWorkoutExercises.count)")
            
            // Filter for our exercise manually
            let matchingExercises = allWorkoutExercises.filter { workoutExercise in
                guard let exercise = workoutExercise.exercise else {
                    print("⚠️ Found WorkoutExercise with no exercise")
                    return false
                }
                
                let matches = exercise.id == currentExercise.id
                if matches {
                    let workoutName = workoutExercise.workout?.name ?? "Unknown Workout"
                    let workoutDate = workoutExercise.workout?.date ?? Date.distantPast
                    let isCurrentWorkout = workoutExercise.id == self.id
                    print("✅ Found match: \(exercise.name) in workout '\(workoutName)' on \(workoutDate) - Current: \(isCurrentWorkout)")
                }
                return matches
            }
            
            print("🎯 Found \(matchingExercises.count) matching exercises")
            return matchingExercises
            
        } catch {
            print("❌ Error fetching all workout exercises: \(error)")
            return []
        }
    }
    

    
    /// Improved method to find last performance with detailed logging
    func findLastPerformance(in context: ModelContext) -> WorkoutExercise? {
        guard self.exercise != nil else {
            print("❌ No exercise assigned to this WorkoutExercise")
            return nil
        }
        
        // Get all matching exercises first
        let allMatches = findAllPerformances(in: context)
        
        // Filter out current workout exercise and sort by date
        let previousPerformances = allMatches
            .filter { $0.id != self.id }
            .compactMap { workoutExercise -> (WorkoutExercise, Date)? in
                guard let workout = workoutExercise.workout else { return nil }
                return (workoutExercise, workout.date)
            }
            .sorted { $0.1 > $1.1 } // Sort by date descending
                
        if let mostRecent = previousPerformances.first {
            return mostRecent.0
        } else {
            print("❌ No previous performances found")
            return nil
        }
    }
    

    
    /// Updated loadSetsFromLastPerformance with debug info
    func loadSetsFromLastPerformance(in context: ModelContext) {
       guard let lastPerformance = findLastPerformance(in: context) else {
            print("❌ No previous performance found for this exercise")
            return
        }

        // Clear existing sets (they're from the old exercise)
        self.sets.removeAll()
        
        // Copy sets from last performance
        for (index, previousSet) in lastPerformance.sets.enumerated() {
            let newSet = ExerciseSet(
                setNumber: index + 1,
                weight: previousSet.weight,
                reps: previousSet.reps
            )
            
            // Copy additional properties if they exist
            newSet.rpe = previousSet.rpe
            newSet.duration = previousSet.duration
            newSet.distance = previousSet.distance
            newSet.notes = previousSet.notes
            newSet.isCompleted = false // Reset completion status
            
            newSet.workoutExercise = self
            self.sets.append(newSet)
        }
        
        // Copy rest time if available
        self.restTime = lastPerformance.restTime
    }
}
