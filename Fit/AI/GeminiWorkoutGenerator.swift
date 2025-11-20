import SwiftUI
import Foundation
import SwiftData
import os.log

// MARK: - Constants

private enum GeminiConstants {
    static let requestTimeout: TimeInterval = 60
    static let resourceTimeout: TimeInterval = 300
    static let minExercisesPerWorkout = 4
    static let maxExercisesPerWorkout = 8
    static let minSetsPerExercise = 2
    static let maxSetsPerExercise = 4
    static let maxRetries = 2
    static let retryDelay: TimeInterval = 1.0
}

// MARK: - URLSession Delegate for TLS Bypass
class TLSBypassDelegate: NSObject, URLSessionDelegate {
    
    func urlSession(
        _ session: URLSession,
        didReceive challenge: URLAuthenticationChallenge,
        completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void
    ) {
        // Check if TLS bypass is enabled in Config
        guard Config.bypassTLSValidation else {
            completionHandler(.performDefaultHandling, nil)
            return
        }
        
        // Bypass certificate validation for corporate proxies
        // WARNING: Only use this when behind a trusted corporate proxy
        if challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust,
           let serverTrust = challenge.protectionSpace.serverTrust {
            AppLogger.warning(AppLogger.network, "⚠️ Bypassing TLS certificate validation for: \(challenge.protectionSpace.host)")
            let credential = URLCredential(trust: serverTrust)
            completionHandler(.useCredential, credential)
        } else {
            completionHandler(.performDefaultHandling, nil)
        }
    }
}

// MARK: - Google Gemini AI Workout Generator Service
class GeminiWorkoutGeneratorService: ObservableObject {
    @Published var isGenerating = false
    @Published var generatedWorkout: Workout?
    @Published var errorMessage: String?
    
    // API key loaded securely from Config
    private let apiKey = Config.geminiAPIKey
    private let apiURL = Config.geminiAPIURL
    private var exercises: [Exercise] = []
    
    // Custom URLSession with TLS bypass for corporate proxies
    private lazy var urlSession: URLSession = {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = GeminiConstants.requestTimeout
        config.timeoutIntervalForResource = GeminiConstants.resourceTimeout
        return URLSession(configuration: config, delegate: TLSBypassDelegate(), delegateQueue: nil)
    }()
    
    func generateWorkout(
        modelContext: ModelContext,
        duration: String,
        trainingType: String,
        difficulty: String,
        workoutSplit: String,
        exercises: [Exercise]
    ) async {
        // Validate inputs
        guard !exercises.isEmpty else {
            await setError("No exercises available to generate workout")
            return
        }
        
        self.exercises = exercises
        await MainActor.run {
            isGenerating = true
            errorMessage = nil
        }
        
        AppLogger.info(AppLogger.ai, "Starting workout generation: duration=\(duration), type=\(trainingType), difficulty=\(difficulty), split=\(workoutSplit)")
        
        let workoutHistory = getWorkoutHistoryForAI(from: modelContext)
        
        let prompt = createPrompt(
            duration: duration,
            trainingType: trainingType,
            difficulty: difficulty,
            workoutSplit: workoutSplit,
            history: workoutHistory
        )
        AppLogger.debug(AppLogger.ai, "Generated prompt with \(workoutHistory.count) characters of workout history")
        
        do {
            let workout = try await requestWorkoutFromGemini(prompt: prompt)
            
            // Validate the workout before setting it
            guard validateWorkout(workout) else {
                throw GeminiWorkoutGeneratorError.invalidWorkout
            }
            
            await setGeneratedWorkout(workout)
            AppLogger.info(AppLogger.ai, "Successfully generated workout: \(workout.name)")
            
        } catch {
            AppLogger.error(AppLogger.ai, "Failed to generate workout: \(error.localizedDescription)")
            await setError(error.localizedDescription)
        }
    }

    // MARK: - Helper Methods
    
    @MainActor
    private func setGeneratedWorkout(_ workout: Workout) {
        self.generatedWorkout = workout
        self.isGenerating = false
    }
    
    @MainActor
    private func setError(_ message: String) {
        self.errorMessage = message
        self.isGenerating = false
    }
    
    /// Validates the generated workout meets basic requirements
    private func validateWorkout(_ workout: Workout) -> Bool {
        guard !workout.exercises.isEmpty else {
            AppLogger.warning(AppLogger.ai, "Workout validation failed: no exercises")
            return false
        }
        
        guard workout.exercises.count >= GeminiConstants.minExercisesPerWorkout,
              workout.exercises.count <= GeminiConstants.maxExercisesPerWorkout else {
            AppLogger.warning(AppLogger.ai, "Workout validation failed: invalid exercise count \(workout.exercises.count)")
            return false
        }
        
        for workoutExercise in workout.exercises {
            guard !workoutExercise.sets.isEmpty else {
                AppLogger.warning(AppLogger.ai, "Workout validation failed: exercise has no sets")
                return false
            }
            
            guard workoutExercise.sets.count >= GeminiConstants.minSetsPerExercise,
                  workoutExercise.sets.count <= GeminiConstants.maxSetsPerExercise else {
                AppLogger.warning(AppLogger.ai, "Workout validation failed: invalid set count")
                return false
            }
        }
        
        return true
    }
    
    private func createPrompt(duration: String, trainingType: String, difficulty: String, workoutSplit: String, history: String) -> String {
        return """
        You are a world-class coach for physical training. 
        Create a detailed \(duration) \(trainingType) workout for a \(difficulty) level person. As a workout Split use \(workoutSplit).
        Respond ONLY with valid JSON in this exact format (no markdown, no additional text):
        {
          "workout_name": "Your Workout Name",
          "exercises": [
            {
              "name": "Exercise Name",
              "primary_muscle": "Chest",
              "exercise_type": "Strength",
              "rest_time": 70,
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

        The workout_name must follow "YYYY-MM-DD [Training Type] [Primary Muscle Groups]" format.
        Use only these values for primary_muscle: Chest, Back, Shoulders, Biceps, Triceps, Forearms, Abs, Obliques, Quadriceps, Hamstrings, Glutes, Calves, Cardio, Full Body
        Use only these values for exercise_type: Strength, Cardio, Flexibility, Plyometric, Powerlifting, Olympic Lifting
        Use only the exercises with the following names and do not invent exercises not listed: \(getExercisesAsList())
        Include 4-8 exercises with 2-4 sets each.
        Propose the best rest time and weight for each of the exercises.
        All rest_time values should be integers (seconds) and realistic for a \(trainingType) workout.
        The total sets × reps × rest must fit within the \(duration) limit.
        The target_weight should in in kg and reasonable for a 56-year-old \(difficulty) lifter. 
        
        Take the following workout history into accout for caclulating the exercises, the weight and the repetitions.
        \(history)
        """
    }
    
    private func getExercisesAsList() -> String {
        var exerciseList: String = ""
        for exercise in exercises {
            if !exerciseList.isEmpty {
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
        
        AppLogger.debug(AppLogger.network, "API Key configured for Gemini API")
        
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
        
        let (data, response) = try await urlSession.data(for: request)
        
        if let httpResponse = response as? HTTPURLResponse {
            AppLogger.debug(AppLogger.network, "HTTP Status Code: \(httpResponse.statusCode)")
            
            if let responseString = String(data: data, encoding: .utf8) {
                AppLogger.debug(AppLogger.network, "Response data: \(responseString)")
            }
            
            switch httpResponse.statusCode {
            case 200:
                break // Success, continue
            case 400:
                AppLogger.error(AppLogger.network, "400 Error: Bad request")
                throw GeminiWorkoutGeneratorError.badRequest
            case 401:
                AppLogger.error(AppLogger.network, "401 Error: Invalid API key")
                throw GeminiWorkoutGeneratorError.invalidAPIKey
            case 403:
                AppLogger.error(AppLogger.network, "403 Error: Forbidden - check API permissions")
                throw GeminiWorkoutGeneratorError.forbidden
            case 429:
                AppLogger.error(AppLogger.network, "429 Error: Rate limit exceeded")
                throw GeminiWorkoutGeneratorError.rateLimitExceeded
            default:
                AppLogger.error(AppLogger.network, "HTTP Error: \(httpResponse.statusCode)")
                throw GeminiWorkoutGeneratorError.apiError
            }
        }
        
        do {
            let geminiResponse = try JSONDecoder().decode(GeminiResponse.self, from: data)
            let workoutJSON = geminiResponse.candidates.first?.content.parts.first?.text ?? ""
            AppLogger.debug(AppLogger.ai, "Gemini Response JSON: \(workoutJSON)")
            
            return try parseWorkoutFromJSON(workoutJSON)
        } catch {
            AppLogger.error(AppLogger.ai, "JSON Decode Error: \(error.localizedDescription)")
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
        
        AppLogger.debug(AppLogger.ai, "Cleaned JSON: \(cleanedJSON)")
        
        guard let jsonData = cleanedJSON.data(using: .utf8) else {
            throw GeminiWorkoutGeneratorError.invalidJSON
        }
        
        let workoutData = try JSONDecoder().decode(AIWorkoutData.self, from: jsonData)
        
        // Create Workout object
        let workout = Workout(name: workoutData.workoutName)
  
        for ii in 0..<exercises.count {
            AppLogger.debug(AppLogger.ai, "Exercise \(ii): \(exercises[ii].id), \(exercises[ii].name)")
        }
        
        // Create exercises and sets
        for (index, exerciseData) in workoutData.exercises.enumerated() {
            if let exercise = exercises.first(where: { $0.name == exerciseData.name }) {
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
            } else {
                AppLogger.warning(AppLogger.ai, "Exercise '\(exerciseData.name)' not found in available exercises")
            }
            /*
            let exercise = Exercise(
                name: exerciseData.name,
                primaryMuscleGroup: muscleGroup,
                exerciseType: exerciseType
            )
             */
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
    case invalidWorkout
    
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
        case .invalidWorkout:
            return "Generated workout doesn't meet validation requirements"
        }
    }
}
