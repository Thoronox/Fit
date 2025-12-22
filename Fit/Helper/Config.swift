//
//  Config.swift
//  Fit
//
//  Configuration manager for API keys and secrets
//

import Foundation

enum Config {
    /// Gemini API Key
    /// Get your free API key from: https://aistudio.google.com/app/apikey
    ///
    /// SETUP: Replace the key below with your actual API key
    /// TODO: Move this to a more secure location before committing to Git
    static var geminiAPIKey: String {
        // Try multiple methods to load the API key
        
        // Method 1: From Info dictionary (Xcode Target > Info settings)
        if let key = Bundle.main.infoDictionary?["GEMINI_API_KEY"] as? String,
           !key.isEmpty,
           key != "$(GEMINI_API_KEY)" {
            return key
        }
        
        // Method 2: From environment variable (for debugging)
        if let key = ProcessInfo.processInfo.environment["GEMINI_API_KEY"],
           !key.isEmpty {
            return key
        }
        
        // Method 3: Read directly from Config.xcconfig file as fallback
        if let configURL = Bundle.main.url(forResource: "Config", withExtension: "xcconfig"),
           let configContent = try? String(contentsOf: configURL),
           let keyLine = configContent.components(separatedBy: .newlines)
               .first(where: { $0.contains("GEMINI_API_KEY") && !$0.hasPrefix("//") }),
           let key = keyLine.components(separatedBy: "=").last?.trimmingCharacters(in: .whitespaces),
           !key.isEmpty {
            return key
        }
        
        fatalError("""
            ⚠️ Gemini API Key not found!
            
            Please set up your API key:
            1. Get a free API key from: https://aistudio.google.com/app/apikey
            2. Edit Config.xcconfig with: GEMINI_API_KEY = your_key_here
            3. In Xcode: Select Fit target > Info tab
            4. Under "Custom iOS Target Properties", click +
            5. Add key: GEMINI_API_KEY, value: $(GEMINI_API_KEY)
            6. Build and run again
            
            Config.xcconfig location: Fit/Config.xcconfig
            """)
    }
    
    static let geminiAPIURL = "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent"
    
    /// Enable TLS certificate bypass for corporate proxies
    /// ⚠️ WARNING: Only enable this when behind a trusted corporate proxy
    /// Set to false in production or when not behind a proxy
    static let bypassTLSValidation = true
}

