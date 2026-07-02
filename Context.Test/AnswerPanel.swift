//
//  AnswerPanel.swift
//  Context.Test
//
//  Created by David Harwardt on 02.07.26.
//

import Cocoa
import SwiftUI

final class AnswerPanel: NSPanel, NSWindowDelegate {
    private var isPinned = false

    init(nearMouse: Bool = true) {
        let width: CGFloat = 300
        let height: CGFloat = 140

        super.init(
            contentRect: NSRect(x: 0, y: 0, width: width, height: height),
            styleMask: [.nonactivatingPanel, .fullSizeContentView, .titled, .resizable],
            backing: .buffered,
            defer: false
        )

        isFloatingPanel = true
        titleVisibility = .hidden
        titlebarAppearsTransparent = true
        isMovableByWindowBackground = true
        hidesOnDeactivate = false
        backgroundColor = .clear
        isOpaque = false
        hasShadow = true
        collectionBehavior = [.canJoinAllSpaces, .transient]
        level = .floating   // sits above normal windows even before pinning
        delegate = self
        
        standardWindowButton(.closeButton)?.isHidden = true
        standardWindowButton(.miniaturizeButton)?.isHidden = true
        standardWindowButton(.zoomButton)?.isHidden = true

        contentView = NSHostingView(rootView:
            AnswerNoteView(
                onPinChanged: { [weak self] pinned in self?.isPinned = pinned },
                onDismiss: { [weak self] in self?.dismissSelf() }
            )
        )

        positionNearMouse(panelSize: NSSize(width: width, height: height))
    }

    private func positionNearMouse(panelSize: NSSize) {
        guard let screen = NSScreen.main else { return }
        let mouseLoc = NSEvent.mouseLocation
        var origin = CGPoint(x: mouseLoc.x - panelSize.width / 2, y: mouseLoc.y - panelSize.height - 16)

        origin.x = min(max(origin.x, screen.visibleFrame.minX + 8),
                        screen.visibleFrame.maxX - panelSize.width - 8)
        origin.y = max(origin.y, screen.visibleFrame.minY + 8)
        setFrameOrigin(origin)
    }

    override var canBecomeKey: Bool { true }

    // Sticky-note dismiss behavior: closes on unfocus, unless pinned.
    func windowDidResignKey(_ notification: Notification) {
        guard !isPinned else { return }
        dismissSelf()
    }

    private func dismissSelf() {
        AnswerPanelController.shared.remove(self)
        close()
    }
}

/// Keeps strong references to all open notes so they aren't deallocated while visible.
@MainActor
final class AnswerPanelController {
    static let shared = AnswerPanelController()
    private var openPanels: [AnswerPanel] = []

    func spawnNew() {
        let panel = AnswerPanel()
        openPanels.append(panel)
        panel.makeKeyAndOrderFront(nil)
    }

    func remove(_ panel: AnswerPanel) {
        openPanels.removeAll { $0 === panel }
    }
}
