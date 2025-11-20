import SwiftUI
import SwiftData
import os.log
import UniformTypeIdentifiers

struct DataManagementView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var showExportSuccess = false
    @State private var showImportSuccess = false
    @State private var showDeleteConfirmation = false
    @State private var showError = false
    @State private var showFileImporter = false
    @State private var errorMessage = ""
    @State private var exportMessage = ""
    @State private var exportFileURL: URL?
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Header
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Data Management")
                            .font(.title2)
                            .fontWeight(.bold)
                        Text("Export, import, or delete your workout data")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.bottom, 10)
                    
                    Divider()
                    
                    // Export Section
                    VStack(alignment: .leading, spacing: 12) {
                        Label("Export Data", systemImage: "arrow.up.doc")
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        Text("Export all your workouts, exercises, and personal records to a file")
                            .font(.caption)
                            .foregroundColor(.gray)
                        
                        Button(action: exportData) {
                            HStack {
                                Image(systemName: "arrow.up.doc.fill")
                                Text("Export to File")
                                Spacer()
                                Image(systemName: "chevron.right")
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.green.opacity(0.2))
                            .foregroundColor(.green)
                            .cornerRadius(8)
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6).opacity(0.5))
                    .cornerRadius(12)
                    
                    // Import Section
                    VStack(alignment: .leading, spacing: 12) {
                        Label("Import Data", systemImage: "arrow.down.doc")
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        Text("Import previously exported data into your app")
                            .font(.caption)
                            .foregroundColor(.gray)
                        
                        Button(action: { showFileImporter = true }) {
                            HStack {
                                Image(systemName: "arrow.down.doc.fill")
                                Text("Import from File")
                                Spacer()
                                Image(systemName: "chevron.right")
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue.opacity(0.2))
                            .foregroundColor(.blue)
                            .cornerRadius(8)
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6).opacity(0.5))
                    .cornerRadius(12)
                    
                    // Delete Section
                    VStack(alignment: .leading, spacing: 12) {
                        Label("Delete Data", systemImage: "trash")
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        Text("Permanently delete all your data. This action cannot be undone.")
                            .font(.caption)
                            .foregroundColor(.gray)
                        
                        Button(action: { showDeleteConfirmation = true }) {
                            HStack {
                                Image(systemName: "trash.fill")
                                Text("Delete All Data")
                                Spacer()
                                Image(systemName: "chevron.right")
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.red.opacity(0.2))
                            .foregroundColor(.red)
                            .cornerRadius(8)
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6).opacity(0.5))
                    .cornerRadius(12)
                    
                    Spacer()
                }
                .padding()
            }
            .navigationTitle("Data Management")
        }
        .alert("Success", isPresented: $showExportSuccess) {
            Button("OK") { showExportSuccess = false }
        } message: {
            Text(exportMessage)
        }
        .alert("Success", isPresented: $showImportSuccess) {
            Button("OK") { showImportSuccess = false }
        } message: {
            Text("Data imported successfully!")
        }
        .alert("Delete Confirmation", isPresented: $showDeleteConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Delete All", role: .destructive) {
                deleteAllData()
            }
        } message: {
            Text("Are you sure you want to permanently delete all your data? This action cannot be undone.")
        }
        .alert("Error", isPresented: $showError) {
            Button("OK") { showError = false }
        } message: {
            Text(errorMessage)
        }
        .fileImporter(
            isPresented: $showFileImporter,
            allowedContentTypes: [.json],
            allowsMultipleSelection: false,
            onCompletion: { result in
                switch result {
                case .success(let urls):
                    if let url = urls.first {
                        handleImportedFile(url)
                    }
                case .failure(let error):
                    AppLogger.error(AppLogger.data, "File selection failed", error: error)
                    errorMessage = "Failed to select file: \(error.localizedDescription)"
                    showError = true
                }
            }
        )
        .sheet(item: $exportFileURL) { url in
            ShareSheet(activityItems: [url])
                .onDisappear {
                    // Clean up temp file
                    try? FileManager.default.removeItem(at: url)
                    exportFileURL = nil
                }
        }
    }
    
    // MARK: - Export Functionality
    private func exportData() {
        do {
            AppLogger.info(AppLogger.data, "Starting data export")
            
            // Fetch all data from modelContext
            let workouts = try modelContext.fetch(FetchDescriptor<Workout>())
            let exercises = try modelContext.fetch(FetchDescriptor<Exercise>())
            let personalRecords = try modelContext.fetch(FetchDescriptor<PersonalRecord>())
            let userProfiles = try modelContext.fetch(FetchDescriptor<UserProfile>())
            let oneRepMaxHistory = try modelContext.fetch(FetchDescriptor<OneRepMaxHistory>())
            
            AppLogger.debug(AppLogger.data, "Fetched \(workouts.count) workouts, \(exercises.count) exercises")
            
            // Convert models to dictionaries for export
            var exercisesData: [[String: Any]] = []
            for exercise in exercises {
                exercisesData.append([
                    "id": exercise.id.uuidString,
                    "name": exercise.name,
                    "primaryMuscleGroup": exercise.primaryMuscleGroup.rawValue,
                    "exerciseType": exercise.exerciseType.rawValue,
                    "instructions": exercise.instructions ?? ""
                ])
            }
            
            var workoutsData: [[String: Any]] = []
            for workout in workouts {
                workoutsData.append([
                    "id": workout.id.uuidString,
                    "name": workout.name,
                    "date": ISO8601DateFormatter().string(from: workout.date),
                    "duration": workout.duration ?? 0,
                    "notes": workout.notes ?? ""
                ])
            }
            
            var profilesData: [[String: Any]] = []
            for profile in userProfiles {
                profilesData.append([
                    "id": profile.id.uuidString,
                    "name": profile.name ?? "",
                    "weightUnit": profile.weightUnit.rawValue,
                    "experienceLevel": profile.experienceLevel.rawValue,
                    "workoutDaysPerWeek": profile.workoutDaysPerWeek
                ])
            }
            
            var recordsData: [[String: Any]] = []
            for record in personalRecords {
                recordsData.append([
                    "id": record.id.uuidString,
                    "weight": record.weight,
                    "reps": record.reps,
                    "date": ISO8601DateFormatter().string(from: record.date),
                    "recordType": record.recordType.rawValue
                ])
            }
            
            var historyData: [[String: Any]] = []
            for history in oneRepMaxHistory {
                var historyDict: [String: Any] = [
                    "id": history.id.uuidString,
                    "oneRepMax": history.oneRepMax,
                    "date": ISO8601DateFormatter().string(from: history.date)
                ]
                
                if let exerciseId = history.exerciseId {
                    historyDict["exerciseId"] = exerciseId.uuidString
                }
                
                if case .high = history.confidence {
                    historyDict["confidence"] = "high"
                } else if case .medium = history.confidence {
                    historyDict["confidence"] = "medium"
                } else if case .low = history.confidence {
                    historyDict["confidence"] = "low"
                }
                
                historyData.append(historyDict)
            }
            
            // Create export data structure
            let exportData: [String: Any] = [
                "exercises": exercisesData,
                "workouts": workoutsData,
                "userProfiles": profilesData,
                "personalRecords": recordsData,
                "oneRepMaxHistory": historyData,
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
            
            // Store URL to present share sheet
            exportFileURL = fileURL
            
            AppLogger.info(AppLogger.data, "Export file created: \(filename)")
            AppLogger.debug(AppLogger.data, "Workouts: \(workouts.count), Exercises: \(exercises.count), Records: \(personalRecords.count)")
        } catch {
            AppLogger.error(AppLogger.data, "Export failed", error: error)
            errorMessage = "Export failed: \(error.localizedDescription)"
            showError = true
        }
    }
    
    // MARK: - Import Functionality
    private func handleImportedFile(_ fileURL: URL) {
        do {
            AppLogger.info(AppLogger.data, "User selected file for import: \(fileURL.lastPathComponent)")
            try importDataFromFile(fileURL)
        } catch {
            AppLogger.error(AppLogger.data, "Import failed", error: error)
            errorMessage = "Import failed: \(error.localizedDescription)"
            showError = true
        }
    }
    
    private func importFromAvailableFiles() {
        do {
            AppLogger.info(AppLogger.data, "Looking for available export files")
            
            // Get documents directory
            guard let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
                throw DataManagementError.noDocumentsDirectory
            }
            
            // Find all export files
            let fileManager = FileManager.default
            let files = try fileManager.contentsOfDirectory(at: documentsURL, includingPropertiesForKeys: [.contentModificationDateKey])
            let exportFiles = files.filter { $0.lastPathComponent.hasPrefix("fit_export_") && $0.pathExtension == "json" }
            
            guard !exportFiles.isEmpty else {
                AppLogger.warning(AppLogger.data, "No export files found in Documents directory")
                errorMessage = "No export files found. Please export data first."
                showError = true
                return
            }
            
            // Sort by modification date, most recent first
            let sortedFiles = exportFiles.sorted { file1, file2 in
                do {
                    let attrs1 = try fileManager.attributesOfItem(atPath: file1.path)
                    let attrs2 = try fileManager.attributesOfItem(atPath: file2.path)
                    let date1 = (attrs1[.modificationDate] as? Date) ?? Date.distantPast
                    let date2 = (attrs2[.modificationDate] as? Date) ?? Date.distantPast
                    return date1 > date2
                } catch {
                    return false
                }
            }
            
            // Get the most recent file
            let mostRecentFile = sortedFiles.first!
            
            AppLogger.debug(AppLogger.data, "Found \(exportFiles.count) export files. Using most recent: \(mostRecentFile.lastPathComponent)")
            AppLogger.info(AppLogger.data, "Importing from: \(mostRecentFile.lastPathComponent)")
            
            // Import from the most recent file
            try importDataFromFile(mostRecentFile)
        } catch {
            AppLogger.error(AppLogger.data, "Failed to import data", error: error)
            errorMessage = "Import failed: \(error.localizedDescription)"
            showError = true
        }
    }
    
    private func importDataFromFile(_ fileURL: URL) throws {
        do {
            AppLogger.info(AppLogger.data, "Starting data import from file: \(fileURL.lastPathComponent)")
            
            // Access the file
            let isSecured = fileURL.startAccessingSecurityScopedResource()
            defer {
                if isSecured {
                    fileURL.stopAccessingSecurityScopedResource()
                }
            }
            
            // Read the file
            let jsonData = try Data(contentsOf: fileURL)
            guard let json = try JSONSerialization.jsonObject(with: jsonData) as? [String: Any] else {
                throw DataManagementError.invalidJSON
            }
            
            AppLogger.debug(AppLogger.data, "Successfully read JSON from file")
            
            // Clear existing data before importing
            AppLogger.debug(AppLogger.data, "Clearing existing data before import")
            try clearAllData()
            
            // Extract and restore data
            var importedCount = 0
            
            // Import exercises first (they're referenced by workouts)
            if let exercisesData = json["exercises"] as? [[String: Any]] {
                AppLogger.debug(AppLogger.data, "Found \(exercisesData.count) exercises to import")
                for exerciseDict in exercisesData {
                    if let exercise = restoreExercise(from: exerciseDict) {
                        modelContext.insert(exercise)
                        importedCount += 1
                    }
                }
                AppLogger.debug(AppLogger.data, "Imported \(importedCount) exercises")
            }
            
            // Import user profiles
            if let profilesData = json["userProfiles"] as? [[String: Any]] {
                AppLogger.debug(AppLogger.data, "Found \(profilesData.count) user profiles to import")
                for profileDict in profilesData {
                    if let profile = restoreUserProfile(from: profileDict) {
                        modelContext.insert(profile)
                    }
                }
            }
            
            // Save intermediate changes
            try modelContext.save()
            
            // Import workouts (will reference exercises and restore their structure)
            if let workoutsData = json["workouts"] as? [[String: Any]] {
                AppLogger.debug(AppLogger.data, "Found \(workoutsData.count) workouts to import")
                for workoutDict in workoutsData {
                    if let workout = restoreWorkout(from: workoutDict) {
                        modelContext.insert(workout)
                    }
                }
                AppLogger.debug(AppLogger.data, "Imported workouts with their exercises and sets")
            }
            
            // Import personal records
            if let recordsData = json["personalRecords"] as? [[String: Any]] {
                AppLogger.debug(AppLogger.data, "Found \(recordsData.count) personal records to import")
                for recordDict in recordsData {
                    if let record = restorePersonalRecord(from: recordDict) {
                        modelContext.insert(record)
                    }
                }
            }
            
            // Import 1RM history
            if let historyData = json["oneRepMaxHistory"] as? [[String: Any]] {
                AppLogger.debug(AppLogger.data, "Found \(historyData.count) 1RM history entries to import")
                for historyDict in historyData {
                    if let history = restoreOneRepMaxHistory(from: historyDict) {
                        modelContext.insert(history)
                    }
                }
            }
            
            // Final save
            try modelContext.save()
            
            AppLogger.info(AppLogger.data, "Data import completed successfully from \(fileURL.lastPathComponent)")
            showImportSuccess = true
        } catch {
            AppLogger.error(AppLogger.data, "Import failed", error: error)
            // Re-throw the error so importFromAvailableFiles can handle it
            throw error
        }
    }
    
    // MARK: - Delete Functionality
    private func deleteAllData() {
        do {
            AppLogger.warning(AppLogger.data, "User initiated data deletion")
            try clearAllData()
            try modelContext.save()
            AppLogger.info(AppLogger.data, "All data deleted successfully")
            showDeleteConfirmation = false
            exportMessage = "All data has been deleted successfully"
            showExportSuccess = true
        } catch {
            AppLogger.error(AppLogger.data, "Failed to delete data", error: error)
            errorMessage = "Failed to delete data: \(error.localizedDescription)"
            showError = true
        }
    }
    
    // MARK: - Data Restoration Methods
    private func restoreExercise(from dict: [String: Any]) -> Exercise? {
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
    
    private func restoreWorkout(from dict: [String: Any]) -> Workout? {
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
        
        return workout
    }
    
    private func restoreUserProfile(from dict: [String: Any]) -> UserProfile? {
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
    
        private func restorePersonalRecord(from dict: [String: Any]) -> PersonalRecord? {
        guard let weight = dict["weight"] as? Double,
              let reps = dict["reps"] as? Int else { return nil }
        
        let recordTypeRaw = dict["recordType"] as? String ?? "calculated"
        let recordType = RecordType(rawValue: recordTypeRaw) ?? .calculated
        
        // Create a minimal exercise for the record (we don't have full exercise data here)
        // In a real scenario, we'd need to look up the exercise by ID from the model context
        let tempExercise = Exercise(id: UUID().uuidString, name: "Unknown", primaryMuscleGroup: .chest, exerciseType: .strength)
        
        let record = PersonalRecord(
            exercise: tempExercise,
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
    private func restoreOneRepMaxHistory(from dict: [String: Any]) -> OneRepMaxHistory? {
        guard let oneRepMax = dict["oneRepMax"] as? Double else { return nil }
        
        // Create a minimal exercise for the history
        let tempExercise = Exercise(id: UUID().uuidString, name: "Unknown", primaryMuscleGroup: .chest, exerciseType: .strength)
        
        let sourceRaw = dict["source"] as? String ?? "calculatedFromSet"
        let source = OneRepMaxSource(rawValue: sourceRaw) ?? .calculatedFromSet
        
        let history = OneRepMaxHistory(
            exercise: tempExercise,
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
    
    // MARK: - Helper Methods
    private func clearAllData() throws {
        AppLogger.debug(AppLogger.data, "Clearing all data from modelContext")
        
        do {
            // Delete in correct order respecting relationships
            // Start with dependent models that have no inverse cascades
            
            // Delete PersonalRecords first (has no dependents)
            try modelContext.delete(model: PersonalRecord.self)
            AppLogger.debug(AppLogger.data, "Deleted PersonalRecords")
            
            // Delete OneRepMaxHistory (has no dependents)
            try modelContext.delete(model: OneRepMaxHistory.self)
            AppLogger.debug(AppLogger.data, "Deleted OneRepMaxHistory")
            
            // Delete Workouts (will cascade to WorkoutExercises and ExerciseSets)
            try modelContext.delete(model: Workout.self)
            AppLogger.debug(AppLogger.data, "Deleted Workouts (cascaded to WorkoutExercises and ExerciseSets)")
            
            // Delete Templates and their exercises
            try modelContext.delete(model: WorkoutTemplate.self)
            AppLogger.debug(AppLogger.data, "Deleted WorkoutTemplates (cascaded to TemplateExercises)")
            
            // Delete UserProfiles (has no dependents)
            try modelContext.delete(model: UserProfile.self)
            AppLogger.debug(AppLogger.data, "Deleted UserProfiles")
            
            // Delete Exercises last (might be referenced, but at this point cascades should handle it)
            try modelContext.delete(model: Exercise.self)
            AppLogger.debug(AppLogger.data, "Deleted Exercises")
            
            // Clean up any remaining orphaned items
            try modelContext.delete(model: WorkoutExercise.self)
            try modelContext.delete(model: ExerciseSet.self)
            try modelContext.delete(model: TemplateExercise.self)
            
            AppLogger.debug(AppLogger.data, "All data cleared from modelContext")
        } catch {
            AppLogger.error(AppLogger.data, "Error during data clearing", error: error)
            throw error
        }
    }
}

// MARK: - Error Handling
enum DataManagementError: LocalizedError {
    case noDocumentsDirectory
    case noExportFileFound
    case invalidJSON
    case serializationError
    
    var errorDescription: String? {
        switch self {
        case .noDocumentsDirectory:
            return "Unable to access documents directory"
        case .noExportFileFound:
            return "No export file found"
        case .invalidJSON:
            return "Invalid JSON format"
        case .serializationError:
            return "Failed to serialize data"
        }
    }
}

// MARK: - URL Identifiable Extension
extension URL: @retroactive Identifiable {
    public var id: String { absoluteString }
}

// MARK: - ShareSheet
struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

#Preview {
    DataManagementView()
        .modelContainer(for: Workout.self, inMemory: true)
}
