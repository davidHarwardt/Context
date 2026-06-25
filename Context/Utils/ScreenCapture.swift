//
//  ScreenCapture.swift
//  Context
//
//  Created by David Harwardt on 25.06.26.
//

import ScreenCaptureKit

enum CaptureError: Error {
    case noDisplay
}

enum ScreenCapture {
    public static func capture(rect: CGRect, screen: NSScreen) async throws -> CGImage {
        let content = try await SCShareableContent.current
        guard let display = content.displays.first(where: {
            $0.displayID == screen.deviceDescription[.init("NSScreenNumber")] as? CGDirectDisplayID
        }) else { throw CaptureError.noDisplay }
        
        let filter = SCContentFilter(display: display, excludingWindows: [])
        let config = SCStreamConfiguration()
        config.sourceRect = rect
        config.width = Int(rect.size.width * screen.backingScaleFactor)
        config.height = Int(rect.size.height * screen.backingScaleFactor)
        let image = try await SCScreenshotManager.captureImage(
            contentFilter: filter,
            configuration: config,
        )
        return image
    }
    
    static func saveOrCopy(rect: CGRect, screen: NSScreen) {
        Task {
            do {
                let image = try await capture(rect: rect, screen: screen)
                let bitmap = NSBitmapImageRep(cgImage: image)
                guard let data = bitmap.representation(using: .png, properties: [:]) else { return }
                // Copy to clipboard, like the system screenshot tool does by default
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setData(data, forType: .png)
                print("copied image")
            } catch {
                print("could not copy: \(error)")
            }
        }
    }
}
