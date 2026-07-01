//
//  SettingsView.swift
//  Context
//
//  Created by David Harwardt on 24.06.26.
//

import SwiftUI

struct SettingsView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        Form {
            OllamaConnectionSection(appState: appState)
            ShortcutRecorderSection()
            InteractionOverviewSection()
        }
        .formStyle(.grouped)
        .frame(width: 520)
        .padding(24)
    }
}

#Preview {
    SettingsView()
}
