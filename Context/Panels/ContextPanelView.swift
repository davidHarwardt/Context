//
//  ContextPanelView.swift
//  Context
//
//  Created by David Harwardt on 24.06.26.
//

import SwiftUI

struct ContextPanelView: View {
    var body: some View {
        QuestionView()
        /* VStack {
            Color.red
        }.frame(minWidth: 200, minHeight: 200) */
    }
}

fileprivate class ContextPanel: NSPanel {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }
}

final class ContextPanelController: NSObject, NSWindowDelegate {
    static let shared = ContextPanelController()
    private var panel: ContextPanel?
    
    func toggle() {
        if let panel, panel.isVisible {
            panel.orderOut(nil)
        } else {
            show()
        }
    }
    
    private func show() {
        let content = ContextPanelView()
        let hosting = NSHostingController(rootView: content)
        
        let panel = ContextPanel(
            contentRect: NSRect(x: 0, y: 0, width: 300, height: 1000),
            styleMask: [.nonactivatingPanel, .fullSizeContentView],
            backing: .buffered,
            defer: false,
        )
        panel.contentViewController = hosting
        panel.titleVisibility = .hidden
        panel.level = .floating
        panel.collectionBehavior = [.fullScreenAuxiliary, .canJoinAllSpaces]
        panel.delegate = self
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = false

        self.panel = panel
        positionAtCursor(panel)
        panel.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
    
    private func positionAtCursor(_ panel: NSPanel) {
        let mouse = NSEvent.mouseLocation
        guard let screen = NSScreen.screens.first(where: {
            $0.frame.contains(mouse)
        }) ?? NSScreen.main else {
            return
        }
            
        let screenFrame = screen.visibleFrame
        var origin = CGPoint(x: mouse.x, y: mouse.y - panel.frame.height)
        origin.x = min(max(origin.x, screenFrame.minX), screenFrame.maxX - panel.frame.width)
        origin.y = min(max(origin.y, screenFrame.minY), screenFrame.maxY - panel.frame.height)
        panel.setFrameOrigin(origin)
    }
    
    func windowDidResignKey(_ notification: Notification) {
        panel?.orderOut(nil)
    }
}
