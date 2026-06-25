//
//  AppState.swift
//  Context
//
//  Created by David Harwardt on 24.06.26.
//

import Foundation
import KeyboardShortcuts
internal import AppKit

extension KeyboardShortcuts.Name {
    static let showContext = Self("showContext", initial: .init(.k, modifiers: [.command]))
    static let screenshotContext = Self("screenshotContext", initial: .init(.k, modifiers: [.command, .shift]))
}

@MainActor
@Observable
final class AppState {
    public var isActive = true
    public var actions = ContextActions()
    
    init() {
        
    }
}
