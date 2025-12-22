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
                    HeaderSection()
                    
                    Divider()
                    
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
            .navigationTitle("Data Management")
        }
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
        
        // Capture the container on the main actor
        let container = modelContext.container
        
        // Perform import on background thread
        Task.detached {
            do {
                // Create a new model context for background import
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

/// Header section with title and description
struct HeaderSection: View {
    var body: some View {
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
    }
}

/// Reusable section for data management actions
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

/// View modifier to handle all alerts
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
        .preferredColorScheme(.dark)
}
