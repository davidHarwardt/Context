//
//  QuestionView.swift
//  Context
//
//  Created by David Harwardt on 25.06.26.
//

import SwiftUI

struct QuestionView: View {
    let actions: ContextActions
    @State private var message: String = ""
    @FocusState private var isMessageFocused: Bool
    
    var body: some View {
        HStack(alignment: .bottom) {
            HStack {
                TextField("Ask something about your documents", text: $message, axis: .vertical)
                    .textFieldStyle(.plain)
                    .lineLimit(1...5)
                    .submitLabel(.send)
                    .focused($isMessageFocused)
                    .onSubmit(sendMessage)
                    .padding(.vertical, 10)
                    .padding(.horizontal, 16)
                    .frame(width: 300)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            HStack(alignment: .bottom) {
                Button(action: sendMessage) {
                    Image(systemName: "arrow.up.circle.fill")
                        .resizable()
                        .frame(width: 24, height: 24)
                        .foregroundColor(message.isEmpty ? .gray : .blue)
                }
                .buttonStyle(.plain)
                .keyboardShortcut(.defaultAction)
                .disabled(message.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || actions.isResponding)
                .padding(4)
                .padding(.bottom, 2)
            }
        }
        .padding(.horizontal, 2)
        .padding(.vertical, 2)
        .glassEffect(in: RoundedRectangle(cornerRadius: CGFloat(20.0)))
        .onAppear {
            isMessageFocused = true
        }
    }
    
    private func sendMessage() {
        let prompt = message.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !prompt.isEmpty else { return }
        actions.ask(prompt)
        message = ""
    }
}

#Preview {
    QuestionView(actions: ContextActions())
}
