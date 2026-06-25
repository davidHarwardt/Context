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
        Toggle("Enabled", isOn: $enabled)
        SettingsLink {
            Text("Settings")
        }
        Button("Quit") {
            NSApplication.shared.terminate(nil)
        }
    }
}

#Preview {
    MenuBarView()
}
