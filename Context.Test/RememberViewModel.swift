//
//  RememberViewModel.swift
//  Context.Test
//
//  Created by David Harwardt on 02.07.26.
//

import SwiftUI

@MainActor @Observable
final class RememberViewModel {
    var selection: SelectionInfo?
    var note = ""
    var saveState: SaveState = .idle

    enum SaveState { case idle, saving, success, failure }

    func reset(with selection: SelectionInfo) {
        self.selection = selection
        note = ""
        saveState = .idle
    }

    func save(onSaved: @escaping () -> Void) {
        guard !note.isEmpty, saveState != .saving, let selection else { return }
        saveState = .saving
        Task {
            let success = await RAGStore.shared.remember(
                text: selection.text, note: note, sourceApp: selection.sourceApp
            )
            saveState = success ? .success : .failure
            if success {
                try? await Task.sleep(nanoseconds: 900_000_000)
                onSaved()
            }
        }
    }
}
