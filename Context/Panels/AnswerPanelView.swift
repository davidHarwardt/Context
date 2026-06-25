//
//  AnswerPanelView.swift
//  Context
//
//  Created by David Harwardt on 25.06.26.
//

import SwiftUI

struct AnswerPanelView: View {
    var body: some View {
        VStack {
            HStack {
                Text("Question").bold()
                Spacer()
                Button(action: {}) {
                    Image(systemName: "pin")
                }
                .buttonStyle(.plain)
            }.padding()
            VStack {
                Text("Lorem ipsum dolor sit amet consecetur, ... some more text")
                    .fixedSize(horizontal: false, vertical: true)
            }.padding()
        }
        .padding(2)
        .frame(width: 300)
        .glassEffect(in: RoundedRectangle(cornerRadius: 20.0))
    }
}

fileprivate class AnswerPanel: NSPanel {
    override var canBecomeKey: Bool { true }
}

final class AnswerPanelController: NSObject, NSWindowDelegate {
    static let shared = AnswerPanelController()
    private var panel: AnswerPanel?
    
    func toggle() {
        if let panel, panel.isVisible {
            panel.orderOut(nil)
        } else { show() }
    }
    
    private func show() {
        let content = AnswerPanelView()
        let hosting = NSHostingController(rootView: content)
        
        let panel = AnswerPanel(
            contentRect: NSRect(x: 0, y: 0, width: 300, height: 1000),
            styleMask: [.nonactivatingPanel, .fullSizeContentView],
            backing: .buffered,
            defer: false,
        )
        panel.contentViewController = hosting
        panel.titleVisibility = .hidden
        panel.level = .floating
        panel.collectionBehavior = [.fullScreenAuxiliary]
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = false
        panel.delegate = self
        panel.isMovableByWindowBackground = true

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
        var origin = CGPoint(x: mouse.x, y: mouse.y + 10)
        origin.x = min(max(origin.x, screenFrame.minX), screenFrame.maxX - panel.frame.width)
        origin.y = min(max(origin.y, screenFrame.minY), screenFrame.maxY - panel.frame.height)
        panel.setFrameOrigin(origin)
    }
}

#Preview {
    AnswerPanelView()
}
