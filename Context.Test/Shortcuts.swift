//
//  Shortcuts.swift
//  Context.Test
//
//  Created by David Harwardt on 02.07.26.
//

import KeyboardShortcuts
internal import AppKit

extension KeyboardShortcuts.Name {
    static let rememberSelection = Self("rememberSelection", initial: .init(.r, modifiers: [.command, .shift]))
    static let queryMemory = Self("queryMemory", initial: .init(.r, modifiers: [.command]))
}
