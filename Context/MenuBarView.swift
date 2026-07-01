//
//  MenuBarView.swift
//  Context
//
//  Created by David Harwardt on 24.06.26.
//

import SwiftUI

struct MenuBarView: View {
    @Environment(AppState.self) private var appState
    @State private var enabled: Bool = true

    var body: some View {
        Button("Ask a Question") {
            ContextPanelController.shared.toggle()
            AnswerPanelController.shared.toggle()
        }.keyboardShortcut("K", modifiers: [.command])

        Button("Screenshot Question") {
            ScreenshotOverlayController.shared.toggle()
        }.keyboardShortcut("K", modifiers: [.command, .shift])

        Divider()
        Toggle("Enabled", isOn: $enabled)
        Divider()

        Button("Getting Started") {
            appState.showIntro()
        }

        SettingsLink {
            Text("Settings")
        }.keyboardShortcut(",", modifiers: [.command])

        Button("Quit") {
            NSApplication.shared.terminate(nil)
        }.keyboardShortcut("Q", modifiers: [.command])
    }
}

#Preview {
    MenuBarView()
}
