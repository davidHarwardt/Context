//
//  OnboardingWindowController.swift
//  Context.Test
//
//  Created by David Harwardt on 02.07.26.
//

import Cocoa
import SwiftUI

final class OnboardingWindowController: NSWindowController {
    static let shared = OnboardingWindowController()

    private init() {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 460, height: 420),
            styleMask: [.titled, .closable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        window.title = "Welcome"
        window.titlebarAppearsTransparent = true
        window.isReleasedWhenClosed = false
        window.center()
        window.contentView = NSHostingView(rootView: OnboardingView(onFinish: { [weak window] in
            window?.close()
        }))
        super.init(window: window)
    }

    required init?(coder: NSCoder) { fatalError() }

    func show() {
        window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}

struct OnboardingView: View {
    let onFinish: () -> Void
    @State private var page = 0

    private let pages: [(icon: String, title: String, body: String)] = [
        ("hand.wave.fill", "Welcome",
         "This app lets you save any selected text on your Mac and ask questions about it later, using a local RAG pipeline — nothing leaves your device."),
        ("text.cursor", "Remember something",
         "Select text anywhere, then press your Remember shortcut (default ⌘R). A small note appears under the selection — add a comment if you like, then save."),
        ("bubble.left.and.bubble.right.fill", "Ask a question",
         "Press your Ask shortcut (default ⌘⇧R) anywhere to spawn a sticky note. Type a question, and it's answered using only what you've saved."),
        ("pin.fill", "Pinning notes",
         "Answer notes close automatically when you click away — like a sticky note you glance at and dismiss. Click the pin icon to keep one open and on top instead."),
        ("gearshape.fill", "You're set",
         "Shortcuts and the Ollama model can be changed anytime from the menu bar icon → Settings. You can reopen this tutorial from there too.")
    ]

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: pages[page].icon)
                .font(.system(size: 44))
                .foregroundStyle(Color.accentColor)

            Text(pages[page].title)
                .font(.title2.bold())

            Text(pages[page].body)
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
                .fixedSize(horizontal: false, vertical: true)

            Spacer()

            HStack(spacing: 6) {
                ForEach(pages.indices, id: \.self) { index in
                    Circle()
                        .fill(index == page ? Color.accentColor : Color.gray.opacity(0.3))
                        .frame(width: 6, height: 6)
                }
            }

            HStack {
                if page > 0 {
                    Button("Back") { page -= 1 }
                }
                Spacer()
                Button(page == pages.count - 1 ? "Get Started" : "Next") {
                    if page == pages.count - 1 {
                        UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
                        onFinish()
                    } else {
                        page += 1
                    }
                }
                .buttonStyle(.borderedProminent)
                .keyboardShortcut(.defaultAction)
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 24)
        }
        .frame(width: 460, height: 420)
    }
}
