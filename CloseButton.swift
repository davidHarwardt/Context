//
//  CloseButton.swift
//  Context.Test
//
//  Created by David Harwardt on 02.07.26.
//

import SwiftUI

struct CloseButton: View {
    let action: () -> Void
    @State private var isHovering = false

    var body: some View {
        Button(action: action) {
            Image(systemName: "xmark")
                .font(.system(size: 9, weight: .bold))
                .foregroundStyle(isHovering ? .white : .secondary)
                .frame(width: 18, height: 18)
                .background(
                    Circle()
                        .fill(isHovering ? Color.red.opacity(0.85) : Color.gray.opacity(0.25))
                )
        }
        .buttonStyle(.plain)
        .onHover { isHovering = $0 }
        .animation(.easeOut(duration: 0.12), value: isHovering)
    }
}
