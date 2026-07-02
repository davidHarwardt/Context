//
//  ChatPanel.swift
//  Context.Test
//
//  Created by David Harwardt on 02.07.26.
//

import Cocoa
import SwiftUI

final class ChatPanel: NSPanel {
    static let shared = ChatPanel()

    private init() {
        super.init(
            contentRect: NSRect(x: 0, y: 0, width: 380, height: 460),
            styleMask: [.nonactivatingPanel, .titled, .closable, .resizable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        isFloatingPanel = true
        titleVisibility = .hidden
        titlebarAppearsTransparent = true
        isMovableByWindowBackground = true
        hidesOnDeactivate = false      // survives losing key/app focus
        backgroundColor = .clear
        isOpaque = false
        hasShadow = true
        collectionBehavior = [.fullScreenAuxiliary]
        level = .normal

        contentView = NSHostingView(rootView: ChatView(panel: self))
        center()
    }

    override var canBecomeKey: Bool { true }

    func toggleShow() {
        if isVisible {
            orderOut(nil)
        } else {
            makeKeyAndOrderFront(nil)
        }
    }

    func setPinned(_ pinned: Bool) {
        level = pinned ? .floating : .normal
    }
}

struct ChatMessage: Identifiable {
    let id = UUID()
    let role: Role
    var text: String
    enum Role { case user, assistant }
}

struct ChatView: View {
    weak var panel: ChatPanel?

    @State private var messages: [ChatMessage] = []
    @State private var input = ""
    @State private var isStreaming = false
    @State private var isPinned = false

    var body: some View {
        VStack(spacing: 0) {
            header

            Divider().opacity(0.2)

            ScrollViewReader { proxy in
                ScrollView {
                    VStack(alignment: .leading, spacing: 10) {
                        ForEach(messages) { message in
                            bubble(for: message)
                                .id(message.id)
                        }
                    }
                    .padding(12)
                }
                .onChange(of: messages.last?.text) { _, _ in
                    if let last = messages.last?.id {
                        withAnimation { proxy.scrollTo(last, anchor: .bottom) }
                    }
                }
            }

            inputRow
        }
        .frame(minWidth: 340, minHeight: 400)
        .glassPanelBackground(cornerRadius: 22)
    }

    private var header: some View {
        HStack {
            Text("Remembered Notes")
                .font(.system(size: 13, weight: .semibold))
            Spacer()
            Button {
                isPinned.toggle()
                panel?.setPinned(isPinned)
            } label: {
                Image(systemName: isPinned ? "pin.fill" : "pin")
                    .foregroundStyle(isPinned ? Color.accentColor : .secondary)
            }
            .buttonStyle(.plain)
            .help(isPinned ? "Unpin" : "Keep on top of other windows")
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
    }

    private func bubble(for message: ChatMessage) -> some View {
        HStack {
            if message.role == .assistant { Spacer(minLength: 0) }
            Text(message.text.isEmpty ? " " : message.text)
                .font(.system(size: 13))
                .foregroundStyle(message.role == .user ? .white : .primary)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(message.role == .user ? Color.accentColor : Color(nsColor: .controlBackgroundColor))
                )
                .frame(maxWidth: 260, alignment: message.role == .user ? .trailing : .leading)
            if message.role == .user { Spacer(minLength: 0) }
        }
        .frame(maxWidth: .infinity, alignment: message.role == .user ? .trailing : .leading)
    }

    private var inputRow: some View {
        HStack(spacing: 8) {
            TextField("Ask about your saved notes…", text: $input, axis: .vertical)
                .textFieldStyle(.plain)
                .font(.system(size: 13))
                .lineLimit(1...4)
                .disabled(isStreaming)
                .onSubmit(send)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(Color(nsColor: .controlBackgroundColor))
                )

            Button(action: send) {
                if isStreaming {
                    ProgressView().controlSize(.small)
                } else {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.system(size: 26))
                        .foregroundStyle(.white, input.isEmpty ? Color.gray.opacity(0.4) : Color.accentColor)
                }
            }
            .buttonStyle(.plain)
            .disabled(input.isEmpty || isStreaming)
        }
        .padding(12)
    }

    private func send() {
        guard !input.isEmpty else { return }
        let question = input
        input = ""
        messages.append(ChatMessage(role: .user, text: question))
        let assistantIndex = messages.count
        messages.append(ChatMessage(role: .assistant, text: ""))
        isStreaming = true

        Task {
            do {
                for try await chunk in RAGStore.shared.query(question: question) {
                    messages[assistantIndex].text += chunk
                }
            } catch {
                messages[assistantIndex].text = "Something went wrong: \(error.localizedDescription)"
            }
            isStreaming = false
        }
    }
}
