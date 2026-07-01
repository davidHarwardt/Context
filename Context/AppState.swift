//
//  AppState.swift
//  Context
//
//  Created by David Harwardt on 24.06.26.
//

import Foundation
import KeyboardShortcuts
import KeychainSwift
internal import AppKit

extension KeyboardShortcuts.Name {
    static let showContext = Self("showContext", initial: .init(.k, modifiers: [.command]))
    static let screenshotContext = Self("screenshotContext", initial: .init(.k, modifiers: [.command, .shift]))
}

@MainActor
@Observable
final class AppState {
    static let defaultOllamaHost = "http://localhost:11434"

    @ObservationIgnored private let defaults = UserDefaults.standard
    @ObservationIgnored private let keychain = KeychainSwift(keyPrefix: "contextSecureWrapper_")

    public var isActive = true
    public var actions: ContextActions
    public var ollamaHost: String {
        didSet {
            defaults.set(ollamaHost, forKey: Self.ollamaHostKey)
            actions.configureOllama(host: ollamaHost, apiKey: ollamaAPIKey)
        }
    }
    public var ollamaAPIKey: String {
        didSet {
            if ollamaAPIKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                keychain.delete(Self.ollamaAPIKeyKey)
            } else {
                keychain.set(ollamaAPIKey, forKey: Self.ollamaAPIKeyKey)
            }
            actions.configureOllama(host: ollamaHost, apiKey: ollamaAPIKey)
        }
    }
    public var hasCompletedIntro: Bool {
        didSet {
            defaults.set(hasCompletedIntro, forKey: Self.hasCompletedIntroKey)
        }
    }

    init() {
        let storedHost = Self.storedOllamaHost(defaults: defaults)
        let storedAPIKey = keychain.get(Self.ollamaAPIKeyKey) ?? ""

        self.ollamaHost = storedHost
        self.ollamaAPIKey = storedAPIKey
        self.hasCompletedIntro = defaults.bool(forKey: Self.hasCompletedIntroKey)
        self.actions = ContextActions(ollamaHost: storedHost, apiKey: storedAPIKey)

        ContextPanelController.shared.configure(actions: actions)
        ScreenshotOverlayController.shared.configure(actions: actions)

        if !hasCompletedIntro {
            Task { @MainActor in
                IntroWindowController.shared.show(appState: self)
            }
        }
    }

    func completeIntro() {
        hasCompletedIntro = true
        IntroWindowController.shared.close()
    }

    func showIntro() {
        IntroWindowController.shared.show(appState: self)
    }

    private static let ollamaHostKey = "ollamaHost"
    private static let ollamaAPIKeyKey = "ollamaAPIKey"
    private static let hasCompletedIntroKey = "hasCompletedIntro"

    private static func storedOllamaHost(defaults: UserDefaults) -> String {
        let storedHost = defaults.string(forKey: ollamaHostKey)?.trimmingCharacters(in: .whitespacesAndNewlines)
        return storedHost?.isEmpty == false ? storedHost! : defaultOllamaHost
    }
}
