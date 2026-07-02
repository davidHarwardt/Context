//
//  RememberPanel.swift
//  Context.Test
//
//  Created by David Harwardt on 02.07.26.
//

import Cocoa
import SwiftUI

@MainActor
final class RememberPanel: NSPanel {
    static let shared = RememberPanel()

    private let viewModel = RememberViewModel()

    private init() {
        let width: CGFloat = 320
        let height: CGFloat = 140

        super.init(
            contentRect: NSRect(x: 0, y: 0, width: width, height: height),
            styleMask: [.nonactivatingPanel, .fullSizeContentView, .titled],
            backing: .buffered,
            defer: false
        )

        isFloatingPanel = true
        level = .floating
        titleVisibility = .hidden
        titlebarAppearsTransparent = true
        isMovableByWindowBackground = true
        hidesOnDeactivate = false
        backgroundColor = .clear
        isOpaque = false
        hasShadow = true
        isReleasedWhenClosed = false   // never let AppKit deallocate this
        collectionBehavior = [.canJoinAllSpaces, .transient]

        standardWindowButton(.closeButton)?.isHidden = true
        standardWindowButton(.miniaturizeButton)?.isHidden = true
        standardWindowButton(.zoomButton)?.isHidden = true

        contentView = NSHostingView(rootView:
            RememberBubbleView(viewModel: viewModel, onDismiss: { [weak self] in self?.hide() })
        )
    }

    /// Call this every time the shortcut fires — repositions and resets state, no re-creation.
    func present(for selection: SelectionInfo) {
        viewModel.reset(with: selection)
        positionBelow(selectionBounds: selection.bounds, panelSize: frame.size)
        orderFrontRegardless()
        makeKey()
    }

    func hide() {
        orderOut(nil)
    }

    private func positionBelow(selectionBounds: CGRect, panelSize: NSSize) {
        let screen = NSScreen.screens.first(where: {
            $0.frame.contains(CGPoint(x: selectionBounds.midX, y: $0.frame.height - selectionBounds.midY))
        }) ?? NSScreen.main ?? NSScreen.screens.first

        guard let screen else { return }
        let flippedY = screen.frame.height - selectionBounds.origin.y

        var origin = CGPoint(
            x: selectionBounds.origin.x,
            y: flippedY - selectionBounds.height - panelSize.height - 8
        )
        if origin.y < screen.visibleFrame.minY {
            origin.y = flippedY + 8
        }
        origin.x = min(max(origin.x, screen.visibleFrame.minX + 8),
                        screen.visibleFrame.maxX - panelSize.width - 8)
        setFrameOrigin(origin)
    }

    override var canBecomeKey: Bool { true }
}

struct RememberBubbleView: View {
    @State var viewModel: RememberViewModel
    let onDismiss: () -> Void
    @FocusState private var focused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                if let app = viewModel.selection?.sourceApp {
                    Text("from \(app)")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                CloseButton(action: onDismiss)
            }
            .padding(.horizontal, 4)

            ScrollView {
                Text(viewModel.selection?.text ?? "")
                    .font(.system(size: 13))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(maxHeight: 50)
            .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(Color.accentColor))

            switch viewModel.saveState {
            case .idle, .saving:
                HStack(spacing: 8) {
                    TextField("Add a note…", text: $viewModel.note, axis: .vertical)
                        .textFieldStyle(.plain)
                        .font(.system(size: 13))
                        .lineLimit(1...3)
                        .focused($focused)
                        .disabled(viewModel.saveState == .saving)
                        .onSubmit { viewModel.save(onSaved: onDismiss) }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 7)
                        .background(RoundedRectangle(cornerRadius: 18, style: .continuous).fill(Color(nsColor: .controlBackgroundColor)))

                    Button(action: { viewModel.save(onSaved: onDismiss) }) {
                        if viewModel.saveState == .saving {
                            ProgressView().controlSize(.small)
                        } else {
                            Image(systemName: "arrow.up.circle.fill")
                                .font(.system(size: 26))
                                .foregroundStyle(.white, viewModel.note.isEmpty ? Color.gray.opacity(0.4) : Color.accentColor)
                        }
                    }
                    .buttonStyle(.plain)
                    .disabled(viewModel.note.isEmpty || viewModel.saveState == .saving)
                }
            case .success:
                Label("Saved", systemImage: "checkmark.circle.fill")
                    .foregroundStyle(.green)
                    .frame(maxWidth: .infinity, alignment: .center)
            case .failure:
                Label("Couldn't save — try again", systemImage: "exclamationmark.circle.fill")
                    .foregroundStyle(.red)
                    .frame(maxWidth: .infinity, alignment: .center)
            }
        }
        .padding(10)
        .glassPanelBackground(cornerRadius: 20)
        .frame(width: 300)
        .fixedSize(horizontal: false, vertical: true)
        .animation(.easeOut(duration: 0.2), value: viewModel.saveState)
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { focused = true }
        }
        // Re-focus every time the panel is re-shown with a new selection
        .onChange(of: viewModel.selection?.text) { _, _ in
            focused = false
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { focused = true }
        }
        .onExitCommand(perform: onDismiss)
    }
}
