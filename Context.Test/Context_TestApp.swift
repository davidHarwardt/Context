//
//  Context_TestApp.swift
//  Context.Test
//
//  Created by David Harwardt on 02.07.26.
//

import SwiftUI
import KeyboardShortcuts

@main
struct RememberThisApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        /* MenuBarExtra("Remember This", systemImage: "brain.head.profile") {
            Button("Open Chat") { ChatPanel.shared.toggleShow() }
                .keyboardShortcut("r", modifiers: [.command])
            Button("Remember") { ChatPanel.shared.toggleShow() }
                .keyboardShortcut("r", modifiers: [.command, .shift])
            Divider()
            Button("Quit") { NSApp.terminate(nil) }
        } */
        MenuBarExtra("Remember This", systemImage: "brain.head.profile") {
            Button("New Note") { AnswerPanelController.shared.spawnNew() }
                .keyboardShortcut("r", modifiers: [.command, .shift])
            Divider()
            Button("Settings…") { SettingsWindowController.shared.show() }
                .keyboardShortcut(",", modifiers: [.command])
            Button("Show Tutorial") { OnboardingWindowController.shared.show() }
            Divider()
            Button("Quit") { NSApp.terminate(nil) }
        }
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var activeRememberPanel: RememberPanel?

    func applicationDidFinishLaunching(_ notification: Notification) {
        /* KeyboardShortcuts.onKeyUp(for: .queryMemory) {
            ChatPanel.shared.toggleShow()
        } */
        KeyboardShortcuts.onKeyUp(for: .queryMemory) {
            Task { @MainActor in
                AnswerPanelController.shared.spawnNew()
            }
        }

        KeyboardShortcuts.onKeyUp(for: .rememberSelection) {
            guard let selection = AccessibilityCapture.captureCurrentSelection() else {
                NSSound.beep()
                return
            }
            RememberPanel.shared.present(for: selection)
        }
        if !UserDefaults.standard.bool(forKey: "hasCompletedOnboarding") {
            OnboardingWindowController.shared.show()
        }
    }
}
