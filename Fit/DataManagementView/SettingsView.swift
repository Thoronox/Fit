import SwiftUI
import SwiftData
import os.log
import UniformTypeIdentifiers

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @AppStorage("selectedAIProvider") private var selectedProvider: AIProvider = .chatGPT
    @AppStorage("selectedChatGPTModel") private var selectedChatGPTModel: ChatGPTModel = .gpt5Nano
    @State private var chatGPTToken: String = ""
    @State private var geminiToken: String = ""
    @State private var showExportSuccess = false
    @State private var showImportSuccess = false
    @State private var showDeleteConfirmation = false
    @State private var showError = false
    @State private var showFileImporter = false
    @State private var errorMessage = ""
    @State private var exportMessage = ""
    @State private var exportFileURL: URL?
    @State private var showChatGPTToken = false
    @State private var showGeminiToken = false
    
    var body: some View {
        VStack(spacing: 0) {
            headerSection
            
            HStack {
                Text("Holger F")

                Spacer()
                Button(action: {
                    print("Tapped")
                }) {
                    Image(systemName: "timer")
                        .symbolRenderingMode(.hierarchical)
                        .foregroundStyle(Color.appPrimary)
                }
                .buttonStyle(.plain)

                Button(action: {
                    print("Tapped")
                }) {
                    Image(systemName: "gearshape")
                        .symbolRenderingMode(.hierarchical)
                        .foregroundStyle(Color.appPrimary)
                }
                .buttonStyle(.plain)
            }
            .padding()
            
            ScrollView {
                VStack(spacing: 20) {
                    // AI Provider Configuration Section
                    aiConfigurationSection
                    
                    DataManagementSection(
                        title: "Export Data",
                        icon: "arrow.up.doc",
                        description: "Export all your workouts, exercises, and personal records to a file",
                        buttonLabel: "Export to File",
                        buttonIcon: "arrow.up.doc.fill",
                        buttonColor: .red,
                        action: exportData
                    )
                    
                    DataManagementSection(
                        title: "Import Data",
                        icon: "arrow.down.doc",
                        description: "Import previously exported data into your app",
                        buttonLabel: "Import from File",
                        buttonIcon: "arrow.down.doc.fill",
                        buttonColor: .red,
                        action: { showFileImporter = true }
                    )
                    
                    DataManagementSection(
                        title: "Delete Data",
                        icon: "trash",
                        description: "Permanently delete all your data. This action cannot be undone.",
                        buttonLabel: "Delete All Data",
                        buttonIcon: "trash.fill",
                        buttonColor: .red,
                        action: { showDeleteConfirmation = true }
                    )
                    
                    Spacer()
                }
                .padding()
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .modifier(AlertsModifier(
            showExportSuccess: $showExportSuccess,
            showImportSuccess: $showImportSuccess,
            showDeleteConfirmation: $showDeleteConfirmation,
            showError: $showError,
            exportMessage: exportMessage,
            errorMessage: errorMessage,
            onDelete: deleteAllData
        ))
        .fileImporter(
            isPresented: $showFileImporter,
            allowedContentTypes: [.json],
            allowsMultipleSelection: false,
            onCompletion: handleFileImportResult
        )
        .sheet(item: $exportFileURL) { url in
            ShareSheet(activityItems: [url])
                .onDisappear {
                    try? FileManager.default.removeItem(at: url)
                }
        }
        .onAppear {
            loadAPITokens()
        }
    }

    @ViewBuilder
    private var headerSection: some View {
        HStack {
            Text("Settings")
                .font(.largeTitle)
                .bold()
            Spacer()
        }
        .padding(.horizontal)
    }
    
    // MARK: - AI Configuration Section
    @ViewBuilder
    private var aiConfigurationSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Label("AI Workout Generator", systemImage: "brain.head.profile")
                .font(.headline)
                .foregroundColor(.white)
            
            Text("Choose your preferred AI provider for generating personalized workouts")
                .font(.caption)
                .foregroundColor(.gray)
            
            // Provider Selection
            Picker("AI Provider", selection: $selectedProvider) {
                ForEach(AIProvider.allCases) { provider in
                    Label(provider.rawValue, systemImage: provider.icon)
                        .tag(provider)
                }
            }
            .pickerStyle(.segmented)
            .padding(.vertical, 4)
            
            // ChatGPT Model Selection (only visible when ChatGPT is selected)
            if selectedProvider == .chatGPT {
                VStack(alignment: .leading, spacing: 8) {
                    Label("ChatGPT Model", systemImage: "cpu")
                        .font(.subheadline)
                        .foregroundColor(.white)
                    
                    Picker("Model", selection: $selectedChatGPTModel) {
                        ForEach(ChatGPTModel.allCases) { model in
                            Text(model.displayName).tag(model)
                        }
                    }
                    .pickerStyle(.menu)
                    .tint(.red)
                }
                
                // ChatGPT Token Configuration
                VStack(alignment: .leading, spacing: 8) {
                    Label("ChatGPT API Key", systemImage: "key.fill")
                        .font(.subheadline)
                        .foregroundColor(selectedProvider == .chatGPT ? .white : .gray)
                    
                    HStack {
                        if showChatGPTToken {
                            TextField("sk-proj-...", text: $chatGPTToken)
                                .textFieldStyle(.roundedBorder)
                                .autocapitalization(.none)
                                .autocorrectionDisabled()
                        } else {
                            SecureField("sk-proj-...", text: $chatGPTToken)
                                .textFieldStyle(.roundedBorder)
                                .autocapitalization(.none)
                                .autocorrectionDisabled()
                        }
                        
                        Button(action: { showChatGPTToken.toggle() }) {
                            Image(systemName: showChatGPTToken ? "eye.slash.fill" : "eye.fill")
                                .foregroundColor(.gray)
                        }
                        .buttonStyle(.plain)
                    }
                    .disabled(selectedProvider != .chatGPT)
                    .opacity(selectedProvider == .chatGPT ? 1.0 : 0.6)
                }
            } else {
                // Gemini Token Configuration
                VStack(alignment: .leading, spacing: 8) {
                    Label("Gemini API Key", systemImage: "key.fill")
                        .font(.subheadline)
                        .foregroundColor(selectedProvider == .gemini ? .white : .gray)
                    
                    HStack {
                        if showGeminiToken {
                            TextField("AIza...", text: $geminiToken)
                                .textFieldStyle(.roundedBorder)
                                .autocapitalization(.none)
                                .autocorrectionDisabled()
                        } else {
                            SecureField("AIza...", text: $geminiToken)
                                .textFieldStyle(.roundedBorder)
                                .autocapitalization(.none)
                                .autocorrectionDisabled()
                        }
                        
                        Button(action: { showGeminiToken.toggle() }) {
                            Image(systemName: showGeminiToken ? "eye.slash.fill" : "eye.fill")
                                .foregroundColor(.gray)
                        }
                        .buttonStyle(.plain)
                    }
                    .disabled(selectedProvider != .gemini)
                    .opacity(selectedProvider == .gemini ? 1.0 : 0.6)
                }

            }
            
            
            
            // Save Button
            Button(action: saveAPITokens) {
                Label("Save API Keys", systemImage: "checkmark.circle.fill")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(.red)
        }
        .padding()
        .background(Color(.systemGray6).opacity(0.5))
        .cornerRadius(12)
        .onChange(of: chatGPTToken) { _, _ in
            // Auto-save when token changes
            saveAPITokens()
        }
        .onChange(of: geminiToken) { _, _ in
            // Auto-save when token changes
            saveAPITokens()
        }
    }
    
    // MARK: - API Token Management
    private func loadAPITokens() {
        chatGPTToken = KeychainHelper.load(key: "chatGPTAPIToken") ?? ""
        geminiToken = KeychainHelper.load(key: "geminiAPIToken") ?? ""
    }
    
    private func saveAPITokens() {
        if !chatGPTToken.isEmpty {
            KeychainHelper.save(key: "chatGPTAPIToken", value: chatGPTToken)
        }
        if !geminiToken.isEmpty {
            KeychainHelper.save(key: "geminiAPIToken", value: geminiToken)
        }
        AppLogger.info(AppLogger.data, "API tokens saved successfully")
    }
    
    // MARK: - File Import Handler
    private func handleFileImportResult(_ result: Result<[URL], Error>) {
        AppLogger.debug(AppLogger.data, "File importer callback received")
        
        DispatchQueue.main.async {
            switch result {
            case .success(let urls):
                AppLogger.debug(AppLogger.data, "File selected successfully, count: \(urls.count)")
                if let url = urls.first {
                    self.handleImportedFile(url)
                } else {
                    AppLogger.warning(AppLogger.data, "No URL in success result")
                    self.errorMessage = "No file was selected"
                    self.showError = true
                }
            case .failure(let error):
                AppLogger.error(AppLogger.data, "File selection failed", error: error)
                self.errorMessage = "Failed to select file: \(error.localizedDescription)"
                self.showError = true
            }
        }
    }
    
    // MARK: - Export Functionality
    private func exportData() {
        do {
            let fileURL = try DataExportService.exportData(from: modelContext)
            exportFileURL = fileURL
        } catch DataManagementError.noDataToExport {
            errorMessage = "No data to export. Start working out first!"
            showError = true
        } catch {
            AppLogger.error(AppLogger.data, "Export failed", error: error)
            errorMessage = "Export failed: \(error.localizedDescription)"
            showError = true
        }
    }
    
    // MARK: - Import Functionality
    private func handleImportedFile(_ fileURL: URL) {
        AppLogger.info(AppLogger.data, "Starting import from: \(fileURL.lastPathComponent)")
        
        let container = modelContext.container
        
        Task.detached {
            do {
                let context = ModelContext(container)
                try DataImportService.importData(from: fileURL, into: context)
                
                await MainActor.run {
                    self.showImportSuccess = true
                    AppLogger.info(AppLogger.data, "Import completed successfully")
                }
            } catch {
                AppLogger.error(AppLogger.data, "Import failed", error: error)
                await MainActor.run {
                    self.errorMessage = "Import failed: \(error.localizedDescription)"
                    self.showError = true
                }
            }
        }
    }
    
    // MARK: - Delete Functionality
    private func deleteAllData() {
        do {
            AppLogger.warning(AppLogger.data, "User initiated data deletion")
            try DataCleanupService.clearAllData(from: modelContext)
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
}

// MARK: - AI Provider Enum
enum AIProvider: String, CaseIterable, Identifiable {
    case chatGPT = "ChatGPT"
    case gemini = "Gemini"
    
    var id: String { rawValue }
    
    var icon: String {
        switch self {
        case .chatGPT: return "bubble.left.and.bubble.right.fill"
        case .gemini: return "sparkles"
        }
    }
}

// MARK: - ChatGPT Model Enum
enum ChatGPTModel: String, CaseIterable, Identifiable {
    case gpt51 = "gpt-5.1"
    case gpt5 = "gpt-5"
    case gpt5Mini = "gpt-5-mini"
    case gpt5Nano = "gpt-5-nano"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .gpt51: return "GPT-5.1"
        case .gpt5: return "GPT-5"
        case .gpt5Mini: return "GPT-5 Mini"
        case .gpt5Nano: return "GPT-5 Nano"
        }
    }
}

// MARK: - Keychain Helper
struct KeychainHelper {
    static func save(key: String, value: String) {
        let data = Data(value.utf8)
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecValueData as String: data
        ]
        
        SecItemDelete(query as CFDictionary)
        SecItemAdd(query as CFDictionary, nil)
    }
    
    static func load(key: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess,
              let data = result as? Data,
              let string = String(data: data, encoding: .utf8) else {
            return nil
        }
        
        return string
    }
    
    static func delete(key: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key
        ]
        
        SecItemDelete(query as CFDictionary)
    }
}

// MARK: - Error Handling
enum DataManagementError: LocalizedError {
    case noDocumentsDirectory
    case noExportFileFound
    case noDataToExport
    case invalidJSON
    case invalidExportFile
    case serializationError
    
    var errorDescription: String? {
        switch self {
        case .noDocumentsDirectory:
            return "Unable to access documents directory"
        case .noExportFileFound:
            return "No export file found"
        case .noDataToExport:
            return "No data to export"
        case .invalidJSON:
            return "The selected file is not in valid JSON format"
        case .invalidExportFile:
            return "The selected file doesn't appear to be a valid Fit export file"
        case .serializationError:
            return "Failed to serialize data"
        }
    }
}

// MARK: - URL Identifiable Extension
extension URL: @retroactive Identifiable {
    public var id: String { absoluteString }
}

// MARK: - View Components

struct DataManagementSection: View {
    let title: String
    let icon: String
    let description: String
    let buttonLabel: String
    let buttonIcon: String
    let buttonColor: Color
    let action: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(title, systemImage: icon)
                .font(.headline)
                .foregroundColor(.white)
            
            Text(description)
                .font(.caption)
                .foregroundColor(.gray)
            
            Button(action: action) {
                Label(buttonLabel, systemImage: buttonIcon)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(buttonColor)
        }
        .padding()
        .background(Color(.systemGray6).opacity(0.5))
        .cornerRadius(12)
    }
}

struct AlertsModifier: ViewModifier {
    @Binding var showExportSuccess: Bool
    @Binding var showImportSuccess: Bool
    @Binding var showDeleteConfirmation: Bool
    @Binding var showError: Bool
    let exportMessage: String
    let errorMessage: String
    let onDelete: () -> Void
    
    func body(content: Content) -> some View {
        content
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
                Button("Delete All", role: .destructive, action: onDelete)
            } message: {
                Text("Are you sure you want to permanently delete all your data? This action cannot be undone.")
            }
            .alert("Error", isPresented: $showError) {
                Button("OK") { showError = false }
            } message: {
                Text(errorMessage)
            }
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

#Preview {
    SettingsView()
        .modelContainer(for: Workout.self, inMemory: true)
        .preferredColorScheme(.dark)
}
