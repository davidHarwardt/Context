//
//  SettingsView.swift
//  Context
//
//  Created by David Harwardt on 24.06.26.
//

import SwiftUI
import KeyboardShortcuts

struct SettingsView: View {
    @Environment(AppState.self) private var appState
    
    @State var isLoading = false
    @State private var password: String?
    @State private var username: String?

    var body: some View {
        Form {
            Section("Shortcuts") {
                KeyboardShortcuts.Recorder("Open Context", name: .showContext)
                KeyboardShortcuts.Recorder("Open Screenshot Context", name: .screenshotContext)
            }
            Section("Credentials") {
                TextField("Username", text: Binding($username, replacingNilWith: ""))
                    .textContentType(.username)
                    .autocorrectionDisabled()
                
                SecureField("Password", text: Binding($password, replacingNilWith: ""))
                    .textContentType(.password)
                    .autocorrectionDisabled()
                
                HStack {
                    Spacer()
                    Button(action: handleLogin) {
                        if isLoading {
                            ProgressView()
                        } else {
                            Text("Sign In")
                        }
                    }.frame(alignment: .trailing)
                }
            }
        }.frame(maxWidth: 300)
        .padding(32)
    }
    
    private func handleLogin() {
        print("signing in user")
    }
}

#Preview {
    SettingsView()
}
