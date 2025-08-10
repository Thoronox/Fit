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
    
    init(name: String, primaryMuscleGroup: MuscleGroup, exerciseType: ExerciseType) {
        self.id = UUID()
        self.name = name
        self.primaryMuscleGroup = primaryMuscleGroup
        self.exerciseType = exerciseType
        self.isCompound = false
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
}

@Model
class ExerciseSet {
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

// MARK: - Workout Templates and Programs

@Model
class WorkoutTemplate {
    var id: UUID
    var name: String
    var longtext: String?
    var exercises: [TemplateExercise] = []
    var estimatedDuration: TimeInterval?
    var targetMuscleGroups: [MuscleGroup] = []
    
    init(name: String) {
        self.id = UUID()
        self.name = name
    }
}

@Model
class TemplateExercise {
    var id: UUID
    var exercise: Exercise?
    var order: Int
    var targetSets: Int
    var targetRepsRange: ClosedRange<Int>? // e.g., 8...12
    var targetWeight: Double?
    var restTime: Int?
    
    init(exercise: Exercise, order: Int, targetSets: Int) {
        self.id = UUID()
        self.exercise = exercise
        self.order = order
        self.targetSets = targetSets
    }
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
    
    init(exercise: Exercise, weight: Double, reps: Int, date: Date = Date()) {
        self.id = UUID()
        self.exercise = exercise
        self.weight = weight
        self.reps = reps
        self.date = date
    }
    
    var oneRepMax: Double {
        weight * (1 + Double(reps) / 30)
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

// MARK: - Extensions for Range Coding
extension ClosedRange: Codable where Bound: Codable {
    enum CodingKeys: String, CodingKey {
        case lowerBound, upperBound
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let lowerBound = try container.decode(Bound.self, forKey: .lowerBound)
        let upperBound = try container.decode(Bound.self, forKey: .upperBound)
        self = lowerBound...upperBound
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(lowerBound, forKey: .lowerBound)
        try container.encode(upperBound, forKey: .upperBound)
    }
}
