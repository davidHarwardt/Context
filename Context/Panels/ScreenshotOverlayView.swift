//
//  ScreenshotOverlayView.swift
//  Context
//
//  Created by David Harwardt on 24.06.26.
//

import SwiftUI

let rectCornerRadius: Double = 32.0


struct ScreenshotOverlayView: View {
    let onComplete: (CGRect) -> Void
    let onCancel: () -> Void
    
    @State private var dragStart: CGPoint?
    @State private var currentRect: CGRect?
    @State private var rectComplete: Bool = false
    
    var body: some View {
        GeometryReader { geo in
            ZStack {
                // Color.blue.opacity(0.1)
                Path { path in
                    path.addRect(CGRect(
                        origin: .init(x: 0, y: 0),
                        size: geo.size
                    ))
                    if let holeRect = currentRect {
                        path.addRoundedRect(
                            in: holeRect, cornerSize: CGSize(width: rectCornerRadius, height: rectCornerRadius)
                        )
                    }
                }
                .fill(Color.black.opacity(0.15), style: FillStyle(eoFill: true))
                if let rect = currentRect {
                    SelectionBoxView(rect: rect)
                }
            }
            .ignoresSafeArea()
            .gesture(
                DragGesture(minimumDistance: 2, coordinateSpace: .local)
                    .onChanged { value in
                        if dragStart == nil { dragStart = value.startLocation }
                        currentRect = normalizedRect(from: dragStart!, to: value.location)
                    }
                    .onEnded { value in
                        if let rect = currentRect, rect.width > 4, rect.height > 4 {
                            rectComplete = true
                            // onComplete(rect)
                        } else {
                            onCancel()
                        }
                    }
            )
            .onExitCommand { onCancel() }
        }
    }
    
    private func normalizedRect(from a: CGPoint, to b: CGPoint) -> CGRect {
        let i = -sin(3.1415 / 4) * rectCornerRadius/2
        return CGRect(
            x: min(a.x, b.x), y: min(a.y, b.y),
            width: abs(b.x - a.x), height: abs(b.y - a.y)
        ).insetBy(dx: CGFloat(i), dy: CGFloat(i))
    }
}


struct SelectionBoxView: View {
    let rect: CGRect

    var body: some View {
        GlassEffectContainer {
            RoundedRectangle(cornerRadius: CGFloat(rectCornerRadius))
                .strokeBorder(lineWidth: 0) // interior stays fully transparent
                .frame(width: rect.width, height: rect.height)
                .glassEffect(.clear, in: RoundedRectangle(cornerRadius: CGFloat(rectCornerRadius)))
                .overlay(
                    RoundedRectangle(cornerRadius: rectCornerRadius)
                        .strokeBorder(Color.white.opacity(0.8), lineWidth: 1.5)
                )
        }
        .position(x: rect.midX, y: rect.midY)
        .allowsHitTesting(false)
    }
}

fileprivate class ScreenshotPanel: NSPanel {
    override var canBecomeKey: Bool { true }
}

final class ScreenshotOverlayController: NSObject, NSWindowDelegate {
    static let shared = ScreenshotOverlayController()
    private var panel: ScreenshotPanel?
    private var actions = ContextActions()
    
    func configure(actions: ContextActions) {
        self.actions = actions
    }
    
    func toggle() {
        if let panel, panel.isVisible {
            panel.orderOut(nil)
        } else {
            show()
        }
    }
    
    private func show() {
        let screen = activeScreen()
        let view = ScreenshotOverlayView(
            onComplete: { [self] rect in
                print("complete \(rect)")
                toggle()
                guard let screen else { return }
                handleCompletedSelection(rect, screen: screen)
            },
            onCancel: { [self] in
                print("cancel")
                toggle()
            },
        )
        let hosting = NSHostingController(rootView: view)
        
        guard let r = activeScreenRect() else {
            print("could not get active screen")
            return
        }
        let panel = ScreenshotPanel(
            contentRect: r,
            styleMask: [.nonactivatingPanel, .borderless],
            backing: .buffered,
            defer: false,
        )
        
        panel.contentViewController = hosting
        // panel.level = .screenSaver
        panel.level = .floating
        panel.ignoresMouseEvents = false
        panel.collectionBehavior = [.fullScreenAuxiliary, .canJoinAllSpaces, .stationary]
        panel.hasShadow = false
        panel.delegate = self
        panel.setFrame(r, display: true)
        panel.isOpaque = false
        panel.backgroundColor = .clear
        
        self.panel = panel
        panel.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
    
    private func handleCompletedSelection(_ rect: CGRect, screen: NSScreen) {
        Task {
            do {
                let image = try await ScreenCapture.capture(rect: rect, screen: screen)
                actions.addContext("Use this screenshot as context for the next answer.", data: .image(image))
                copyToPasteboard(image)
            } catch {
                print("could not capture screenshot context: \(error)")
            }
        }
    }
    
    private func copyToPasteboard(_ image: CGImage) {
        let bitmap = NSBitmapImageRep(cgImage: image)
        guard let data = bitmap.representation(using: .png, properties: [:]) else { return }
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setData(data, forType: .png)
    }
    
    private func activeScreenRect() -> NSRect? {
        activeScreen()?.frame
    }
    
    private func activeScreen() -> NSScreen? {
        let mouse = NSEvent.mouseLocation
        return NSScreen.screens.first(where: {
            $0.frame.contains(mouse)
        }) ?? NSScreen.main
    }
    
    func windowDidResignKey(_ notification: Notification) {
        panel?.orderOut(nil)
    }
}
