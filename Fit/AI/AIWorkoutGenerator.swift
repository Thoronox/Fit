import SwiftUI
import Foundation
import SwiftData
import os.log

// MARK: - Configuration

private enum AIServiceConstants {
    static let requestTimeout: TimeInterval = 60
    static let resourceTimeout: TimeInterval = 300
    static let minExercisesPerWorkout = 4
    static let maxExercisesPerWorkout = 8
    static let minSetsPerExercise = 3
    static let maxSetsPerExercise = 4
}

// MARK: - AI Workout Generator Protocol

protocol AIWorkoutGeneratorService: AnyObject {
    var isGenerating: Bool { get set }
    var generatedWorkout: Workout? { get set }
    var errorMessage: String? { get set }
    
    func generateWorkout(
        modelContext: ModelContext,
        duration: String,
        trainingType: String,
        difficulty: String,
        workoutSplit: String,
        exercises: [Exercise]
    ) async
}

// MARK: - Shared Protocol Extensions

extension AIWorkoutGeneratorService {
    
    func validateWorkout(
        _ workout: Workout,
        minExercises: Int = AIServiceConstants.minExercisesPerWorkout,
        maxExercises: Int = AIServiceConstants.maxExercisesPerWorkout,
        minSets: Int = AIServiceConstants.minSetsPerExercise,
        maxSets: Int = AIServiceConstants.maxSetsPerExercise
    ) -> Bool {
        guard !workout.exercises.isEmpty else {
            AppLogger.warning(AppLogger.ai, "Workout validation failed: no exercises")
            return false
        }
        
        guard workout.exercises.count >= minExercises,
              workout.exercises.count <= maxExercises else {
            AppLogger.warning(AppLogger.ai, "Workout validation failed: invalid exercise count \(workout.exercises.count)")
            return false
        }
        
        for workoutExercise in workout.exercises {
            guard !workoutExercise.sets.isEmpty else {
                AppLogger.warning(AppLogger.ai, "Workout validation failed: exercise has no sets")
                return false
            }
            
            guard workoutExercise.sets.count >= minSets,
                  workoutExercise.sets.count <= maxSets else {
                AppLogger.warning(AppLogger.ai, "Workout validation failed: invalid set count")
                return false
            }
        }
        
        return true
    }
    
    func parseWorkoutFromJSON(_ jsonString: String, exercises: [Exercise]) throws -> Workout {
        let cleanedJSON = cleanJSONString(jsonString)
        
        guard let jsonData = cleanedJSON.data(using: .utf8) else {
            throw AIWorkoutError.invalidJSON
        }
        
        let workoutData = try JSONDecoder().decode(AIWorkoutData.self, from: jsonData)
        return buildWorkout(from: workoutData, exercises: exercises)
    }
    
    private func cleanJSONString(_ jsonString: String) -> String {
        var cleaned = jsonString
            .replacingOccurrences(of: "```json", with: "")
            .replacingOccurrences(of: "```", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        
        if let startIndex = cleaned.firstIndex(of: "{"),
           let endIndex = cleaned.lastIndex(of: "}") {
            cleaned = String(cleaned[startIndex...endIndex])
        }
        
        return cleaned
    }
    
    private func buildWorkout(from workoutData: AIWorkoutData, exercises: [Exercise]) -> Workout {
        let workout = Workout(name: workoutData.workoutName)
        
        for (index, exerciseData) in workoutData.exercises.enumerated() {
            guard let exercise = exercises.first(where: { $0.name == exerciseData.name }) else {
                AppLogger.warning(AppLogger.ai, "Exercise not found: \(exerciseData.name)")
                continue
            }
            
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

// MARK: - Prompt Builder

struct WorkoutPromptBuilder {
    let duration: String
    let trainingType: String
    let difficulty: String
    let workoutSplit: String
    let exercises: [Exercise]
    let history: String
    
    func build() -> String {
        """
        You are a world-class coach for physical training and program design.
        Your task is to generate a structured, progressive hypertrophy workout based strictly on the constraints and data below.
        
        GOAL
        - Primary goal: \(trainingType)
        - Training level: \(difficulty)
        - Age: 56 years
        - Workout duration limit: \(duration) minutes
        - Split: \(workoutSplit)
        
        OUTPUT RULES (STRICT)
        - Respond ONLY with valid JSON
        - No markdown
        - No explanations
        - No comments
        - No additional text
        - The JSON must match the exact schema provided below
        
        JSON FORMAT (EXACT)
        {
          "workout_name": "\(trainingType) \(workoutSplit) \(duration)",
          "exercises": [
            {
              "name": "Exercise Name",
              "primary_muscle": "Chest",
              "exercise_type": "Strength",
              "rest_time": 75,
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
        
        ENUM CONSTRAINTS
        - primary_muscle must be one of:
          Chest, Back, Shoulders, Biceps, Triceps, Forearms, Abs, Obliques,
          Quadriceps, Hamstrings, Glutes, Calves, Cardio, Full Body
        
        - exercise_type must be one of:
          Strength, Cardio, Flexibility, Plyometric, Powerlifting, Olympic Lifting
        
        EXERCISE CONSTRAINTS
        - Use ONLY the following exercise names
        - Do NOT invent or rename exercises
        
        Allowed exercises:
        \(exercisesList)
        
        WORKOUT STRUCTURE RULES
        - Include 4–8 exercises
        - Each exercise must have 3–4 sets
        - No supersets
        - All rest_time values must be integers (seconds)
        - Rest times must be realistic for \(trainingType) (60–120 seconds)
        
        HYPERTROPHY GUIDELINES
        - Compound lifts: 8–12 reps
        - Isolation lifts: 10–15 reps
        - Target intensity: 65–75% of estimated 1RM
        - Final set should end with ~1–3 reps in reserve (RIR)
        - No sets to absolute failure

        STRENGTH TRAINING GUIDELINES
        - Primary goal: Maximal and submaximal strength
        - Primary compound lifts: 3–6 reps
        - Secondary compound lifts: 4–8 reps
        - Isolation lifts: 6–10 reps (limited use)
        - Target intensity: 75–88% of estimated 1RM
        - Final set should end with 2–4 reps in reserve (RIR)
        - No grinding reps or technical failure
        
        PROGRESSION LOGIC (MANDATORY)
        - Progress primarily by increasing reps within the target rep range
        - Increase weight ONLY if all sets in the most recent workout reached the upper rep target
        - Weight increases must be conservative:
          - Dumbbells: +1–2 kg
          - Barbell / bodyweight loading: +2–5%
        - If recent performance declined, maintain or slightly reduce weight
        - Do NOT introduce sudden volume or load spikes
        
        AGE-SPECIFIC CONSIDERATIONS
        - Avoid maximal or near-maximal loading (>85% 1RM)
        - Favor controlled tempo and joint-friendly loading
        - Prefer exercises already tolerated well in recent history
        
        TIME CALCULATION MODEL
        - Each set takes approximately 40 seconds to perform
        - Rest applies only between sets
        - Total workout duration (sets + rest) must not exceed 45 minutes
        
        WORKOUT HISTORY INTERPRETATION
        - Use estimated 1RM values to determine working weights
        - Favor exercises that show stable or improving performance
        - Avoid repeating identical movement patterns at maximal volume
        - Balance push, pull, hinge, squat, and core work
        
        WORKOUT HISTORY 
        \(history)
        """
    }
    
    private var exercisesList: String {
        exercises.map { $0.name }.joined(separator: ", ")
    }
}

// MARK: - Gemini Service

final class GeminiWorkoutGeneratorService: ObservableObject, AIWorkoutGeneratorService {
    @Published var isGenerating = false
    @Published var generatedWorkout: Workout?
    @Published var errorMessage: String?
    
    private let apiKey: String
    private let apiURL = "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent"
    
    private lazy var urlSession: URLSession = {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = AIServiceConstants.requestTimeout
        config.timeoutIntervalForResource = AIServiceConstants.resourceTimeout
        return URLSession(configuration: config, delegate: TLSBypassDelegate(), delegateQueue: nil)
    }()
    
    init(apiKey: String) {
        self.apiKey = apiKey
    }
    
    func generateWorkout(
        modelContext: ModelContext,
        duration: String,
        trainingType: String,
        difficulty: String,
        workoutSplit: String,
        exercises: [Exercise]
    ) async {
        guard !exercises.isEmpty else {
            await setError("No exercises available to generate workout")
            return
        }
        
        await MainActor.run {
            isGenerating = true
            errorMessage = nil
        }
        
        AppLogger.info(AppLogger.ai, "Starting Gemini workout generation: duration=\(duration), type=\(trainingType), difficulty=\(difficulty), split=\(workoutSplit)")
        
        let workoutHistory = getWorkoutHistoryForAI(from: modelContext)
        let prompt = WorkoutPromptBuilder(
            duration: duration,
            trainingType: trainingType,
            difficulty: difficulty,
            workoutSplit: workoutSplit,
            exercises: exercises,
            history: workoutHistory
        ).build()
        
        AppLogger.debug(AppLogger.ai, "Generated prompt with \(workoutHistory.count) characters of workout history")
        
        do {
            let workout = try await requestWorkoutFromGemini(prompt: prompt, exercises: exercises)
            
            guard validateWorkout(workout) else {
                throw AIWorkoutError.invalidWorkout
            }
            
            await setGeneratedWorkout(workout)
            AppLogger.info(AppLogger.ai, "Successfully generated workout: \(workout.name)")
            
        } catch {
            AppLogger.error(AppLogger.ai, "Failed to generate workout: \(error.localizedDescription)")
            await setError(error.localizedDescription)
        }
    }
    
    @MainActor
    private func setGeneratedWorkout(_ workout: Workout) {
        generatedWorkout = workout
        isGenerating = false
    }
    
    @MainActor
    private func setError(_ message: String) {
        errorMessage = message
        isGenerating = false
    }
    
    private func requestWorkoutFromGemini(prompt: String, exercises: [Exercise]) async throws -> Workout {
        guard let url = URL(string: "\(apiURL)?key=\(apiKey)") else {
            throw AIWorkoutError.invalidURL
        }
        
        let requestBody: [String: Any] = [
            "contents": [
                [
                    "parts": [
                        ["text": prompt]
                    ]
                ]
            ]
        ]
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        
        let (data, response) = try await urlSession.data(for: request)
        
        try validateHTTPResponse(response, data: data)
        
        let geminiResponse = try JSONDecoder().decode(GeminiResponse.self, from: data)
        guard let workoutJSON = geminiResponse.candidates.first?.content.parts.first?.text else {
            throw AIWorkoutError.invalidJSON
        }
        
        AppLogger.debug(AppLogger.ai, "Gemini Response JSON: \(workoutJSON)")
        return try parseWorkoutFromJSON(workoutJSON, exercises: exercises)
    }
    
    private func validateHTTPResponse(_ response: URLResponse, data: Data) throws {
        guard let httpResponse = response as? HTTPURLResponse else { return }
        
        AppLogger.debug(AppLogger.network, "HTTP Status Code: \(httpResponse.statusCode)")
        
        if let responseString = String(data: data, encoding: .utf8) {
            AppLogger.debug(AppLogger.network, "Response data: \(responseString)")
        }
        
        switch httpResponse.statusCode {
        case 200:
            return
        case 400:
            throw AIWorkoutError.badRequest
        case 401:
            throw AIWorkoutError.invalidAPIKey
        case 403:
            throw AIWorkoutError.forbidden
        case 429:
            throw AIWorkoutError.rateLimitExceeded
        default:
            throw AIWorkoutError.apiError(statusCode: httpResponse.statusCode)
        }
    }
}

// MARK: - ChatGPT Service

final class ChatGPTWorkoutGeneratorService: ObservableObject, AIWorkoutGeneratorService {
    @Published var isGenerating = false
    @Published var generatedWorkout: Workout?
    @Published var errorMessage: String?
    
    private let apiKey: String
    private let model: String
    private let apiURL = "https://api.openai.com/v1/chat/completions"
    
    private lazy var urlSession: URLSession = {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = AIServiceConstants.requestTimeout
        config.timeoutIntervalForResource = AIServiceConstants.resourceTimeout
        return URLSession(configuration: config)
    }()
    
    init(apiKey: String, model: String) {
        self.apiKey = apiKey
        self.model = model
    }
    
    func generateWorkout(
        modelContext: ModelContext,
        duration: String,
        trainingType: String,
        difficulty: String,
        workoutSplit: String,
        exercises: [Exercise]
    ) async {
        guard !exercises.isEmpty else {
            await setError("No exercises available to generate workout")
            return
        }
        
        await MainActor.run {
            isGenerating = true
            errorMessage = nil
        }
        
        AppLogger.info(AppLogger.ai, "Starting ChatGPT workout generation: duration=\(duration), type=\(trainingType), difficulty=\(difficulty), split=\(workoutSplit)")
        
        let workoutHistory = getWorkoutHistoryForAI(from: modelContext)
        let prompt = WorkoutPromptBuilder(
            duration: duration,
            trainingType: trainingType,
            difficulty: difficulty,
            workoutSplit: workoutSplit,
            exercises: exercises,
            history: workoutHistory
        ).build()
        
        AppLogger.debug(AppLogger.ai, "Prompt is:\n\(prompt)")
        
        do {
            let workout = try await requestWorkoutFromChatGPT(prompt: prompt, exercises: exercises)
            
            guard validateWorkout(workout) else {
                throw AIWorkoutError.invalidWorkout
            }
            
            await setGeneratedWorkout(workout)
            AppLogger.info(AppLogger.ai, "Successfully generated ChatGPT workout: \(workout.name)")
            
        } catch {
            AppLogger.error(AppLogger.ai, "Failed to generate ChatGPT workout: \(error.localizedDescription)")
            await setError(error.localizedDescription)
        }
    }
    
    @MainActor
    private func setGeneratedWorkout(_ workout: Workout) {
        generatedWorkout = workout
        isGenerating = false
    }
    
    @MainActor
    private func setError(_ message: String) {
        errorMessage = message
        isGenerating = false
    }
    
    private func requestWorkoutFromChatGPT(prompt: String, exercises: [Exercise]) async throws -> Workout {
        guard let url = URL(string: apiURL) else {
            throw AIWorkoutError.invalidURL
        }
        
        let requestBody: [String: Any] = [
            "model": model,
            "messages": [
                ["role": "system", "content": "You are a world-class coach for physical training and program design."],
                ["role": "user", "content": prompt]
            ]
        ]
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        
        let (data, response) = try await urlSession.data(for: request)
        
        try validateOpenAIResponse(response, data: data)
        
        let chatResponse = try JSONDecoder().decode(ChatGPTResponse.self, from: data)
        guard let workoutJSON = chatResponse.choices.first?.message.content else {
            throw AIWorkoutError.invalidJSON
        }
        
        return try parseWorkoutFromJSON(workoutJSON, exercises: exercises)
    }
    
    private func validateOpenAIResponse(_ response: URLResponse, data: Data) throws {
        guard let httpResponse = response as? HTTPURLResponse else { return }
        
        AppLogger.debug(AppLogger.network, "ChatGPT HTTP Status Code: \(httpResponse.statusCode)")
        
        guard httpResponse.statusCode == 200 else {
            if let apiError = try? JSONDecoder().decode(OpenAIErrorResponse.self, from: data) {
                AppLogger.error(AppLogger.network, "OpenAI error: \(apiError.error.message)")
                throw AIWorkoutError.openAIError(message: apiError.error.message)
            }
            throw AIWorkoutError.apiError(statusCode: httpResponse.statusCode)
        }
    }
}

// MARK: - TLS Bypass Delegate

final class TLSBypassDelegate: NSObject, URLSessionDelegate {
    func urlSession(
        _ session: URLSession,
        didReceive challenge: URLAuthenticationChallenge,
        completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void
    ) {
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

// MARK: - Error Types

enum AIWorkoutError: LocalizedError {
    case invalidURL
    case apiError(statusCode: Int)
    case invalidJSON
    case invalidAPIKey
    case forbidden
    case badRequest
    case rateLimitExceeded
    case invalidWorkout
    case openAIError(message: String)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid API URL"
        case .apiError(let statusCode):
            return "API request failed with status code \(statusCode)"
        case .invalidJSON:
            return "Invalid JSON response from AI"
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
        case .openAIError(let message):
            return "OpenAI error: \(message)"
        }
    }
}

// MARK: - Response Models

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

struct ChatGPTResponse: Codable {
    let choices: [ChatGPTChoice]
}

struct ChatGPTChoice: Codable {
    let message: ChatGPTMessage
}

struct ChatGPTMessage: Codable {
    let content: String
}

struct OpenAIErrorResponse: Codable {
    let error: OpenAIErrorDetail
}

struct OpenAIErrorDetail: Codable {
    let message: String
    let type: String?
    let param: String?
    let code: String?
}

// MARK: - AI Workout Data Models

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
