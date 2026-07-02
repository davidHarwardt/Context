//
//  SettingsWindowController.swift
//  Context.Test
//
//  Created by David Harwardt on 02.07.26.
//

import Cocoa
import SwiftUI
import KeyboardShortcuts

final class SettingsWindowController: NSWindowController {
    static let shared = SettingsWindowController()

    private init() {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 420, height: 320),
            styleMask: [.titled, .closable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        window.title = "Settings"
        window.titlebarAppearsTransparent = true
        window.isReleasedWhenClosed = false
        window.center()
        window.contentView = NSHostingView(rootView: SettingsView())
        super.init(window: window)
    }

    required init?(coder: NSCoder) { fatalError() }

    func show() {
        window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}

struct SettingsView: View {
    @AppStorage("ollamaModel") private var ollamaModel = "llama3.2"
    @AppStorage("ollamaHost") private var ollamaHost = "http://localhost:11434"

    var body: some View {
        TabView {
            Form {
                Section("Capture") {
                    KeyboardShortcuts.Recorder("Remember selection:", name: .rememberSelection)
                    KeyboardShortcuts.Recorder("Ask a question:", name: .queryMemory)
                }
            }
            .padding(20)
            .tabItem { Label("Shortcuts", systemImage: "keyboard") }

            Form {
                Section("Ollama") {
                    TextField("Model", text: $ollamaModel)
                    TextField("Host", text: $ollamaHost)
                    Text("Model must already be pulled — run `ollama pull \(ollamaModel)` in Terminal.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(20)
            .tabItem { Label("Model", systemImage: "cpu") }

            Form {
                Section("Storage") {
                    Text("Snippets are embedded on-device and stored locally — nothing leaves your Mac except the chat request to Ollama, which also runs locally.")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                    Button("Reset All Saved Notes", role: .destructive) {
                        RAGStore.shared.resetAll()
                    }
                }
            }
            .padding(20)
            .tabItem { Label("Data", systemImage: "externaldrive") }
        }
        .frame(width: 420, height: 320)
    }
}
