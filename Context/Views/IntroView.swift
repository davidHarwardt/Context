//
//  IntroView.swift
//  Context
//
//  Created by David Harwardt on 30.06.26.
//

import SwiftUI
import KeyboardShortcuts
internal import AppKit

struct IntroView: View {
    @Bindable var appState: AppState
    let showsDoneButton: Bool

    init(appState: AppState, showsDoneButton: Bool = true) {
        self.appState = appState
        self.showsDoneButton = showsDoneButton
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Context")
                    .font(.largeTitle.bold())
                Text("A menu bar assistant for quick questions, screenshots, and remembered context.")
                    .font(.body)
                    .foregroundStyle(.secondary)
            }

            Form {
                OllamaConnectionSection(appState: appState)
                ShortcutRecorderSection()
                InteractionOverviewSection()
            }
            .formStyle(.grouped)

            if showsDoneButton {
                HStack {
                    Spacer()
                    Button("Start Using Context") {
                        appState.completeIntro()
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
        }
        .padding(28)
        .frame(width: 560)
    }
}

struct OllamaConnectionSection: View {
    @Bindable var appState: AppState

    var body: some View {
        Section("Ollama") {
            TextField("Host", text: $appState.ollamaHost)
                .textContentType(.URL)
                .autocorrectionDisabled()

            SecureField("API Key", text: $appState.ollamaAPIKey)
                .textContentType(.password)
                .autocorrectionDisabled()

            Text("Use the local default unless your Ollama-compatible endpoint runs elsewhere or requires a bearer token.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}

struct ShortcutRecorderSection: View {
    var body: some View {
        Section("Shortcuts") {
            KeyboardShortcuts.Recorder("Open chat", name: .showContext)
            KeyboardShortcuts.Recorder("Capture screenshot", name: .screenshotContext)
        }
    }
}

struct InteractionOverviewSection: View {
    private let items: [(String, String, String)] = [
        ("message", "Ask", "Open the chat box and send a question to Ollama."),
        ("viewfinder", "Capture", "Select part of the screen and attach it as visual context."),
        ("tray.full", "Remember", "Prompts, answers, files, and screenshots are indexed locally for retrieval."),
        ("point.3.connected.trianglepath.dotted", "Connect", "Relevant matches are added to future prompts so related ideas can surface together.")
    ]

    var body: some View {
        Section("How Context Works") {
            ForEach(items, id: \.1) { item in
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: item.0)
                        .frame(width: 20)
                        .foregroundStyle(.tint)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(item.1)
                            .font(.headline)
                        Text(item.2)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.vertical, 4)
            }
        }
    }
}

@MainActor
final class IntroWindowController {
    static let shared = IntroWindowController()
    private var window: NSWindow?

    func show(appState: AppState) {
        if let window {
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        let hostingController = NSHostingController(rootView: IntroView(appState: appState))
        let window = NSWindow(contentViewController: hostingController)
        window.title = "Welcome to Context"
        window.styleMask = [.titled, .closable, .miniaturizable]
        window.isReleasedWhenClosed = false
        window.center()
        window.setContentSize(NSSize(width: 560, height: 620))

        self.window = window
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    func close() {
        window?.close()
        window = nil
    }
}
