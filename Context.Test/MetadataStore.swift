//
//  MetadataStore.swift
//  Context.Test
//
//  Created by David Harwardt on 02.07.26.
//

import Foundation

struct SnippetMetadata: Codable, Identifiable {
    let id: UUID          // must match the UUID VecturaKit returns from addDocuments
    let text: String
    let note: String
    let sourceApp: String?
    let createdAt: Date
}

@MainActor
final class MetadataStore {
    static let shared = MetadataStore()

    private var entries: [UUID: SnippetMetadata] = [:]
    private let fileURL: URL

    private init() {
        let dir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("RememberThis", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        fileURL = dir.appendingPathComponent("metadata.json")
        load()
    }

    func add(_ metadata: SnippetMetadata) {
        entries[metadata.id] = metadata
        save()
    }

    func metadata(for id: UUID) -> SnippetMetadata? { entries[id] }

    private func load() {
        guard let data = try? Data(contentsOf: fileURL),
              let decoded = try? JSONDecoder().decode([SnippetMetadata].self, from: data) else { return }
        entries = Dictionary(uniqueKeysWithValues: decoded.map { ($0.id, $0) })
    }

    private func save() {
        let array = Array(entries.values)
        guard let data = try? JSONEncoder().encode(array) else { return }
        try? data.write(to: fileURL, options: .atomic)
    }
}
