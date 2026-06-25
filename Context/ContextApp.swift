//
//  ContextApp.swift
//  Context
//
//  Created by David Harwardt on 24.06.26.
//

import SwiftUI
import KeyboardShortcuts

@main
struct ContextApp: App {
    @State private var appState = AppState()
    
    init() {
        KeyboardShortcuts.onKeyDown(for: .showContext) {
            ContextPanelController.shared.toggle()
        }
        KeyboardShortcuts.onKeyDown(for: .screenshotContext) {
            ScreenshotOverlayController.shared.toggle()
        }
    }
    
    var body: some Scene {
        MenuBarExtra("Context", systemImage: "sparkles") {
            MenuBarView().environment(appState)
        }
        
        Settings {
            SettingsView().environment(appState)
        }
    }
}
