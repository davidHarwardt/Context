//
//  QuestionView.swift
//  Context
//
//  Created by David Harwardt on 25.06.26.
//

import SwiftUI

struct QuestionView: View {
    @State var message: String = ""
    
    var body: some View {
        HStack(alignment: .bottom) {
            HStack {
                TextField("Ask something", text: $message, axis: .vertical)
                    .textFieldStyle(.plain)
                    .lineLimit(1...5)
                    .padding(.vertical, 10)
                    .padding(.horizontal, 16)
                    .frame(width: 300)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            HStack(alignment: .bottom) {
                Button(action: {
                    print("sent: \(message)")
                }) {
                    Image(systemName: "arrow.up.circle.fill")
                        .resizable()
                        .frame(width: 24, height: 24)
                        .foregroundColor(message.isEmpty ? .gray : .blue)
                }
                .buttonStyle(.plain)
                .disabled(message.isEmpty)
                .padding(4)
                .padding(.bottom, 2)
            }
        }
        .padding(.horizontal, 2)
        .padding(.vertical, 2)
        .glassEffect(in: RoundedRectangle(cornerRadius: CGFloat(20.0)))
    }
}

#Preview {
    QuestionView()
}
