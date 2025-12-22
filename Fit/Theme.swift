//
//  Theme.swift
//  Fit
//
//  Created on 27.11.25.
//

import SwiftUI

/// Global app theme colors and styles
extension Color {
    /// Primary app color used for buttons, icons, and interactive elements
    static let appPrimary = Color.red
    
    /// Primary color with reduced opacity for backgrounds
    static let appPrimaryBackground = Color.red.opacity(0.7)
    
    /// Primary color for selection states
    static let appSelection = Color.red
}

/// Global app theme configuration
enum AppTheme {
    /// Primary tint color for the entire app
    static let tintColor: Color = .red
    
    /// Primary color for buttons and interactive elements
    static let primaryColor: Color = .red
    
    /// Background color for primary elements
    static let primaryBackground: Color = .red.opacity(0.7)
    
    /// Selection color
    static let selectionColor: Color = .red
}
