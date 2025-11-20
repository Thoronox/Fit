//
//  Logger.swift
//  Fit
//
//  Centralized logging utility for the app using os.log for structured logging
//

import Foundation
import os.log

/// Centralized logging utility that provides structured logging with different levels
class AppLogger {
    /// Shared instance for app-wide logging
    static let shared = AppLogger()
    
    // MARK: - Logger Categories
    
    /// Main app lifecycle and initialization
    static let app = os.Logger(subsystem: Bundle.main.bundleIdentifier ?? "Fit", category: "App")
    
    /// Exercise-related operations
    static let exercise = os.Logger(subsystem: Bundle.main.bundleIdentifier ?? "Fit", category: "Exercise")
    
    /// Workout generation and management
    static let workout = os.Logger(subsystem: Bundle.main.bundleIdentifier ?? "Fit", category: "Workout")
    
    /// Data persistence and database operations
    static let data = os.Logger(subsystem: Bundle.main.bundleIdentifier ?? "Fit", category: "Data")
    
    /// One Rep Max calculations and history
    static let oneRepMax = os.Logger(subsystem: Bundle.main.bundleIdentifier ?? "Fit", category: "OneRepMax")
    
    /// AI and Gemini API operations
    static let ai = os.Logger(subsystem: Bundle.main.bundleIdentifier ?? "Fit", category: "AI")
    
    /// UI and view-related operations
    static let ui = os.Logger(subsystem: Bundle.main.bundleIdentifier ?? "Fit", category: "UI")
    
    /// Networking operations
    static let network = os.Logger(subsystem: Bundle.main.bundleIdentifier ?? "Fit", category: "Network")
    
    // MARK: - Convenience Methods
    
    /// Log debug information
    static func debug(_ logger: os.Logger, _ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        let fileName = URL(fileURLWithPath: file).lastPathComponent
        logger.debug("[\(fileName):\(line) \(function)] \(message)")
    }
    
    /// Log informational message
    static func info(_ logger: os.Logger, _ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        let fileName = URL(fileURLWithPath: file).lastPathComponent
        logger.info("[\(fileName):\(line) \(function)] \(message)")
    }
    
    /// Log warning message
    static func warning(_ logger: os.Logger, _ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        let fileName = URL(fileURLWithPath: file).lastPathComponent
        logger.warning("[\(fileName):\(line) \(function)] \(message)")
    }
    
    /// Log error message
    static func error(_ logger: os.Logger, _ message: String, error: Error? = nil, file: String = #file, function: String = #function, line: Int = #line) {
        let fileName = URL(fileURLWithPath: file).lastPathComponent
        let errorDesc = error.map { ": \($0.localizedDescription)" } ?? ""
        logger.error("[\(fileName):\(line) \(function)] \(message)\(errorDesc)")
    }
    
    /// Log fault (critical error)
    static func fault(_ logger: os.Logger, _ message: String, error: Error? = nil, file: String = #file, function: String = #function, line: Int = #line) {
        let fileName = URL(fileURLWithPath: file).lastPathComponent
        let errorDesc = error.map { ": \($0.localizedDescription)" } ?? ""
        logger.fault("[\(fileName):\(line) \(function)] 🔴 FAULT: \(message)\(errorDesc)")
    }
}
