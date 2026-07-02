//
//  AnswerNoteView.swift
//  Context.Test
//
//  Created by David Harwardt on 02.07.26.
//

import SwiftUI

struct AnswerNoteView: View {
    let onPinChanged: (Bool) -> Void
    let onDismiss: () -> Void

    @State private var question = ""
    @State private var answer = ""
    @State private var isStreaming = false
    @State private var hasAsked = false
    @State private var isPinned = false
    @FocusState private var focused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            header

            if hasAsked {
                Text(question)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.secondary)
                    .lineLimit(2)

                ScrollView {
                    Text(answer.isEmpty ? " " : answer)
                        .font(.system(size: 13))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .textSelection(.enabled)
                }
                .frame(maxHeight: 220)

                if isStreaming {
                    ProgressView().controlSize(.small)
                }
            } else {
                TextField("Ask about your saved notes…", text: $question, axis: .vertical)
                    .textFieldStyle(.plain)
                    .font(.system(size: 13))
                    .lineLimit(1...4)
                    .focused($focused)
                    .onSubmit(ask)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(Color(nsColor: .controlBackgroundColor))
                    )
            }
        }
        .padding(12)
        .glassPanelBackground(cornerRadius: 20)
        .frame(width: 280)
        .fixedSize(horizontal: false, vertical: true)
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { focused = true }
        }
        .onExitCommand { onDismiss() }
    }

    private var header: some View {
        HStack {
            Text(hasAsked ? "Answer" : "New note")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(.secondary)
            Spacer()
            Button {
                isPinned.toggle()
                onPinChanged(isPinned)
            } label: {
                Image(systemName: isPinned ? "pin.fill" : "pin")
                    .font(.system(size: 11))
                    .foregroundStyle(isPinned ? Color.accentColor : .secondary)
            }
            .buttonStyle(.plain)
            .help(isPinned ? "Unpin — will close when you click away" : "Pin — keeps this note open and on top")
            
            CloseButton(action: onDismiss)
        }
    }

    private func ask() {
        guard !question.isEmpty, !isStreaming else { return }
        hasAsked = true
        isStreaming = true

        Task {
            do {
                for try await chunk in RAGStore.shared.query(question: question) {
                    answer += chunk
                }
            } catch {
                answer = "Something went wrong: \(error.localizedDescription)"
            }
            isStreaming = false
        }
    }
}
