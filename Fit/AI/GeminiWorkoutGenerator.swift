import SwiftUI
import Foundation
import SwiftData

// MARK: - Google Gemini AI Workout Generator Service
class GeminiWorkoutGeneratorService: ObservableObject {
    @Query var exercises: [Exercise]

    @Published var isGenerating = false
    @Published var generatedWorkout: Workout?
    @Published var errorMessage: String?
    
    // Get your free API key from: https://aistudio.google.com/app/apikey
    private let apiKey = "AIzaSyDbQmxH89hT8xWYd2xlYeiEqG2aMZ8Jfh0"
    private let apiURL = "https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent"
    
    func generateWorkout(
        duration: String,
        trainingType: String,
        difficulty: String,
        equipment: String
    ) async {
        await MainActor.run {
            isGenerating = true
            errorMessage = nil
        }
        
        let prompt = createPrompt(
            duration: duration,
            trainingType: trainingType,
            difficulty: difficulty,
            equipment: equipment
        )
print (prompt)
        do {
            let workout = try await requestWorkoutFromGemini(prompt: prompt)
            
            // Fix: Call MainActor method directly
            await setGeneratedWorkout(workout)
            
        } catch {
            await MainActor.run {
                self.errorMessage = error.localizedDescription
                self.isGenerating = false
            }
        }
    }

    // Helper method to set the workout on MainActor
    @MainActor
    private func setGeneratedWorkout(_ workout: Workout) {
        self.generatedWorkout = workout
        self.isGenerating = false
    }
    
    
    private func createPrompt(duration: String, trainingType: String, difficulty: String, equipment: String) -> String {
        return """
        You are a world-class coach for physical training. 
        Create a detailed \(duration) \(trainingType) workout for a \(difficulty) level person using \(equipment).
        Consider that the person is 56 years old. 
        
        Respond ONLY with valid JSON in this exact format (no markdown, no additional text):
        {
          "workout_name": "Your Workout Name",
          "exercises": [
            {
              "name": "Exercise Name",
              "primary_muscle": "Chest",
              "exercise_type": "Strength",
              "rest_time": 89
              "sets": [
                {
                  "set_number": 1,
                  "target_reps": 10,
                  "target_weight": 20.0,
                  "notes": "Optional instructions"
                }
              ]
            }
          ]
        }
        
        Use only these values for primary_muscle: Chest, Back, Shoulders, Biceps, Triceps, Forearms, Abs, Obliques, Quadriceps, Hamstrings, Glutes, Calves, Cardio, Full Body
        Use only these values for exercise_type: Strength, Cardio, Flexibility, Plyometric, Powerlifting, Olympic Lifting
        Use only the exercises with the following names: \(getExercisesAsList())
        Include 4-8 exercises with 2-4 sets each.
        Propose the best rest time and weight for each of the exercises.
        Make sure you do not exceed the duration of the workout as mentioned above.
        """
    }
    
    private func getExercisesAsList() -> String {

        var exerciseList: String = ""
        for exercise in exercises {
            if exerciseList.isEmpty {
                exerciseList += ", "
            }
            exerciseList += exercise.name
        }
        return exerciseList
    }
    
    private func requestWorkoutFromGemini(prompt: String) async throws -> Workout {
        guard let url = URL(string: "\(apiURL)?key=\(apiKey)") else {
            throw GeminiWorkoutGeneratorError.invalidURL
        }
        
        let requestBody: [String: Any] = [
            "contents": [
                [
                    "parts": [
                        [
                            "text": prompt
                        ]
                    ]
                ]
            ]
        ]
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        if let httpResponse = response as? HTTPURLResponse {
            print("HTTP Status Code: \(httpResponse.statusCode)")
            
            if let responseString = String(data: data, encoding: .utf8) {
                print("Response data: \(responseString)")
            }
            
            switch httpResponse.statusCode {
            case 200:
                break // Success, continue
            case 400:
                print("400 Error: Bad request")
                throw GeminiWorkoutGeneratorError.badRequest
            case 401:
                print("401 Error: Invalid API key")
                throw GeminiWorkoutGeneratorError.invalidAPIKey
            case 403:
                print("403 Error: Forbidden - check API permissions")
                throw GeminiWorkoutGeneratorError.forbidden
            case 429:
                print("429 Error: Rate limit exceeded")
                throw GeminiWorkoutGeneratorError.rateLimitExceeded
            default:
                print("HTTP Error: \(httpResponse.statusCode)")
                throw GeminiWorkoutGeneratorError.apiError
            }
        }
        
        do {
            let geminiResponse = try JSONDecoder().decode(GeminiResponse.self, from: data)
            let workoutJSON = geminiResponse.candidates.first?.content.parts.first?.text ?? ""
            print("Gemini Response JSON: \(workoutJSON)")
            
            return try parseWorkoutFromJSON(workoutJSON)
        } catch {
            print("JSON Decode Error: \(error)")
            throw GeminiWorkoutGeneratorError.invalidJSON
        }
    }
    
    private func parseWorkoutFromJSON(_ jsonString: String) throws -> Workout {
        // Clean up the JSON string
        var cleanedJSON = jsonString
            .replacingOccurrences(of: "```json", with: "")
            .replacingOccurrences(of: "```", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Extract JSON from response
        if let startIndex = cleanedJSON.firstIndex(of: "{"),
           let endIndex = cleanedJSON.lastIndex(of: "}") {
            cleanedJSON = String(cleanedJSON[startIndex...endIndex])
        }
        
        print("Cleaned JSON: \(cleanedJSON)")
        
        guard let jsonData = cleanedJSON.data(using: .utf8) else {
            throw GeminiWorkoutGeneratorError.invalidJSON
        }
        
        let workoutData = try JSONDecoder().decode(AIWorkoutData.self, from: jsonData)
        
        // Create Workout object
        let workout = Workout(name: workoutData.workoutName)
        
        // Create exercises and sets
        for (index, exerciseData) in workoutData.exercises.enumerated() {
            let muscleGroup = MuscleGroup(rawValue: exerciseData.primaryMuscle) ?? .fullBody
            let exerciseType = ExerciseType(rawValue: exerciseData.exerciseType) ?? .strength
            
            let exercise = Exercise(
                name: exerciseData.name,
                primaryMuscleGroup: muscleGroup,
                exerciseType: exerciseType
            )
            
            let workoutExercise = WorkoutExercise(exercise: exercise, order: index)
            workoutExercise.restTime = exerciseData.restTime
            for setData in exerciseData.sets {
                let exerciseSet = ExerciseSet(
                    setNumber: setData.setNumber,
                    weight: setData.targetWeight,
                    reps: setData.targetReps
                )
                exerciseSet.notes = setData.notes
                exerciseSet.workoutExercise = workoutExercise
                
                workoutExercise.sets.append(exerciseSet)
            }
            
            workoutExercise.workout = workout
            workout.exercises.append(workoutExercise)
        }
        
        return workout
    }
}

// MARK: - Gemini Response Structure
struct GeminiResponse: Codable {
    let candidates: [GeminiCandidate]
}

struct GeminiCandidate: Codable {
    let content: GeminiContent
}

struct GeminiContent: Codable {
    let parts: [GeminiPart]
}

struct GeminiPart: Codable {
    let text: String
}

// MARK: - Reuse existing workout data structures
struct AIWorkoutData: Codable {
    let workoutName: String
    let exercises: [AIExerciseData]
    
    enum CodingKeys: String, CodingKey {
        case workoutName = "workout_name"
        case exercises
    }
}

struct AIExerciseData: Codable {
    let name: String
    let primaryMuscle: String
    let exerciseType: String
    let restTime: Int
    let sets: [AISetData]
    
    enum CodingKeys: String, CodingKey {
        case name
        case primaryMuscle = "primary_muscle"
        case exerciseType = "exercise_type"
        case restTime = "rest_time"
        case sets
    }
}

struct AISetData: Codable {
    let setNumber: Int
    let targetReps: Int
    let targetWeight: Double
    let notes: String?
    
    enum CodingKeys: String, CodingKey {
        case setNumber = "set_number"
        case targetReps = "target_reps"
        case targetWeight = "target_weight"
        case notes
    }
}

// MARK: - Gemini Error Types
enum GeminiWorkoutGeneratorError: Error, LocalizedError {
    case invalidURL
    case apiError
    case invalidJSON
    case networkError
    case invalidAPIKey
    case forbidden
    case badRequest
    case rateLimitExceeded
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid API URL"
        case .apiError:
            return "API request failed"
        case .invalidJSON:
            return "Invalid JSON response from AI"
        case .networkError:
            return "Network connection error"
        case .invalidAPIKey:
            return "Invalid API key - get one free at https://aistudio.google.com/app/apikey"
        case .forbidden:
            return "Access forbidden - check API permissions"
        case .badRequest:
            return "Bad request - check the prompt format"
        case .rateLimitExceeded:
            return "Rate limit exceeded - try again in a minute"
        }
    }
}

// MARK: - Alternative Mock Generator (No API needed)
class MockWorkoutGeneratorService: ObservableObject {
    @Published var isGenerating = false
    @Published var generatedWorkout: Workout?
    @Published var errorMessage: String?
    
    func generateWorkout(
        duration: String,
        trainingType: String,
        difficulty: String,
        equipment: String
    ) async {
        await MainActor.run { isGenerating = true }
        
        // Simulate API delay
        try? await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
        
        await MainActor.run {
            let workout = createMockWorkout(duration: duration, trainingType: trainingType, difficulty: difficulty, equipment: equipment)
            self.generatedWorkout = workout
            self.isGenerating = false
        }
    }
    
    private func createMockWorkout(duration: String, trainingType: String, difficulty: String, equipment: String) -> Workout {
        let workout = Workout(name: "\(difficulty) \(duration) \(trainingType) Workout")
        
        // Create different workouts based on type
        let exercises: [(String, MuscleGroup, ExerciseType, [(Int, Int, Double)])] = {
            switch trainingType.lowercased() {
            case "strength":
                return [
                    ("Push-ups", .chest, .strength, [(12, 15, 0), (10, 12, 0), (8, 10, 0)]),
                    ("Squats", .quadriceps, .strength, [(15, 20, 0), (12, 15, 0), (10, 12, 0)]),
                    ("Pull-ups", .back, .strength, [(5, 8, 0), (4, 6, 0), (3, 5, 0)]),
                    ("Lunges", .glutes, .strength, [(10, 12, 0), (10, 12, 0), (8, 10, 0)])
                ]
            case "cardio":
                return [
                    ("Jumping Jacks", .fullBody, .cardio, [(30, 45, 0), (30, 45, 0), (30, 45, 0)]),
                    ("High Knees", .quadriceps, .cardio, [(20, 30, 0), (20, 30, 0), (20, 30, 0)]),
                    ("Burpees", .fullBody, .cardio, [(8, 12, 0), (8, 12, 0), (6, 10, 0)]),
                    ("Mountain Climbers", .abs, .cardio, [(20, 30, 0), (20, 30, 0), (15, 25, 0)])
                ]
            default:
                return [
                    ("Push-ups", .chest, .strength, [(10, 12, 0), (10, 12, 0)]),
                    ("Squats", .quadriceps, .strength, [(15, 20, 0), (15, 20, 0)]),
                    ("Plank", .abs, .strength, [(30, 45, 0), (30, 45, 0)])
                ]
            }
        }()
        
        for (index, (exerciseName, muscleGroup, exerciseType, sets)) in exercises.enumerated() {
            let exercise = Exercise(name: exerciseName, primaryMuscleGroup: muscleGroup, exerciseType: exerciseType)
            let workoutExercise = WorkoutExercise(exercise: exercise, order: index)
            
            for (setIndex, (minReps, maxReps, weight)) in sets.enumerated() {
                let reps = difficulty == "Beginner" ? minReps : maxReps
                let exerciseSet = ExerciseSet(setNumber: setIndex + 1, weight: weight, reps: reps)
                exerciseSet.notes = equipment == "Bodyweight" ? "Use bodyweight only" : "Adjust weight as needed"
                exerciseSet.workoutExercise = workoutExercise
                
                workoutExercise.sets.append(exerciseSet)
            }
            
            workoutExercise.workout = workout
            workout.exercises.append(workoutExercise)
        }
        
        return workout
    }
}
