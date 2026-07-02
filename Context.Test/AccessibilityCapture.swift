//
//  AccessibilityCapture.swift
//  Context.Test
//
//  Created by David Harwardt on 02.07.26.
//

import Cocoa
import ApplicationServices

struct SelectionInfo {
    let text: String
    let bounds: CGRect
    let sourceApp: String?
}

enum AccessibilityCapture {
    enum SelectionCaptureError: Error {
        case accessibilityNotGranted
        case noSelectionFound
    }
    
    static func captureCurrentSelection() -> SelectionInfo? {
        guard AXIsProcessTrusted() else {
            let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true]
            AXIsProcessTrustedWithOptions(options as CFDictionary)
            print("not trusted")
            return nil
        }

        guard let frontApp = NSWorkspace.shared.frontmostApplication else {
            print("no frontmost app")
            return nil
        }
        print("🟢 Frontmost app: \(frontApp.localizedName ?? "?") — bundleID: \(frontApp.bundleIdentifier ?? "?")")
        let appElement = AXUIElementCreateApplication(frontApp.processIdentifier)

        var focusedElementRef: CFTypeRef?
        guard AXUIElementCopyAttributeValue(appElement, kAXFocusedUIElementAttribute as CFString, &focusedElementRef) == .success,
              let focusedElement = focusedElementRef else { return nil }
        let element = focusedElement as! AXUIElement

        var selectedTextRef: CFTypeRef?
        guard AXUIElementCopyAttributeValue(element, kAXSelectedTextAttribute as CFString, &selectedTextRef) == .success,
              let selectedText = selectedTextRef as? String,
              !selectedText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return nil }

        var rangeRef: CFTypeRef?
        AXUIElementCopyAttributeValue(element, kAXSelectedTextRangeAttribute as CFString, &rangeRef)
        
        print("🟢 Got selection: \(selectedText.prefix(30))")

        var bounds = CGRect.zero
        if let rangeRef {
            var boundsRef: CFTypeRef?
            if AXUIElementCopyParameterizedAttributeValue(element, kAXBoundsForRangeParameterizedAttribute as CFString, rangeRef, &boundsRef) == .success,
               let boundsValue = boundsRef {
                var rect = CGRect.zero
                AXValueGetValue(boundsValue as! AXValue, .cgRect, &rect)
                bounds = rect
            }
        }

        if bounds == .zero {
            let mouseLoc = NSEvent.mouseLocation
            bounds = CGRect(x: mouseLoc.x, y: NSScreen.main!.frame.height - mouseLoc.y, width: 0, height: 0)
        }

        return SelectionInfo(text: selectedText.trimmingCharacters(in: .whitespacesAndNewlines), bounds: bounds, sourceApp: frontApp.localizedName)
    }
}
