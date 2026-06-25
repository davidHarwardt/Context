//
//  MenuBarView.swift
//  Context
//
//  Created by David Harwardt on 24.06.26.
//

import SwiftUI

struct MenuBarView: View {
    @State var enabled: Bool = true
    
    var body: some View {
        Button("Ask a Question") {
            NSApplication.shared.terminate(nil)
        }.keyboardShortcut("K", modifiers: [.command])
        Button("Screenshot Question") {
            NSApplication.shared.terminate(nil)
        }.keyboardShortcut("K", modifiers: [.command, .shift])
        Divider()
        Toggle("Enabled", isOn: $enabled)
        Divider()
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
