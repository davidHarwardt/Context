//
//  RAGStore.swift
//  Context.Test
//
//  Created by David Harwardt on 02.07.26.
//

import Foundation
import VecturaKit
import VecturaNLKit
import Ollama
internal import NaturalLanguage

@MainActor
final class RAGStore {
    static let shared = RAGStore()

    private var vectorDB: VecturaKit?
    private let ollamaClient = Client.default

    private var chatModel: String { UserDefaults.standard.string(forKey: "ollamaModel") ?? "mistral:latest" }
    
    private var setupTask: Task<Void, Never>? = nil
    
    private init() {
        self.setupTask = Task { [weak self] in await self?.setup() }
    }
    
    func resetAll() {
        Task {
            await setupTask?.value
            try? await vectorDB?.reset()
        }
    }

    private func setup() async {
        print("calling setup")
        do {
            let config = try VecturaConfig(name: "remember-this-db")
            print("config ok")
            let embedder = try await NLContextualEmbedder(language: .english)
            print("embedder ok ok")
            vectorDB = try await VecturaKit(config: config, embedder: embedder)
            print("assigned vectorDB ok")
        } catch {
            print("Failed to initialize VecturaKit: \(error)")
        }
    }

    // MARK: - Save

    /// Returns true on success so the UI can show confirmation feedback.
    func remember(text: String, note: String, sourceApp: String?) async -> Bool {
        await self.setupTask?.value
        guard let vectorDB else { return false }
        do {
            // Combine note into the embedded text so semantic search also matches on the note,
            // not just the raw snippet — helps retrieval when the user's question uses their
            // own phrasing rather than the source text's wording.
            let combinedForEmbedding = note.isEmpty ? text : "\(text)\n\nNote: \(note)"
            let ids = try await vectorDB.addDocuments(texts: [combinedForEmbedding])
            guard let id = ids.first else { return false }

            MetadataStore.shared.add(SnippetMetadata(
                id: id, text: text, note: note, sourceApp: sourceApp, createdAt: Date()
            ))
            return true
        } catch {
            print("Save failed: \(error)")
            return false
        }
    }

    // MARK: - Query (RAG)

    /// Streams the answer token-by-token so the chat UI can render incrementally.
    func query(question: String) -> AsyncThrowingStream<String, Error> {
        AsyncThrowingStream { continuation in
            Task {
                await self.setupTask?.value
                do {
                    guard let vectorDB else {
                        continuation.finish(throwing: NSError(domain: "RAGStore", code: 1))
                        return
                    }

                    let results = try await vectorDB.search(query: .text(question), numResults: 2)

                    // NOTE: field names on the search result type (.id, .text, .score) are my
                    // best understanding of VecturaKit's shape — verify against the installed
                    // package version if this doesn't compile as-is.
                    let contextBlocks: [String] = results.compactMap { result in
                        guard let meta = MetadataStore.shared.metadata(for: result.id) else { return nil }
                        var block = ""
                        if !meta.note.isEmpty { block += "Note: \(meta.note)" }
                        block += "\nSnippet: \(meta.text)"
                        if let app = meta.sourceApp { block += "\nSource: \(app)" }
                        return block
                    }
                    
                    print(contextBlocks)

                    let contextText = contextBlocks.isEmpty
                        ? "No saved snippets matched this question."
                        : contextBlocks.joined(separator: "\n---\n")

                    let stream = try ollamaClient.chatStream(
                        model: .init(rawValue: chatModel)!,
                        messages: [
                            .system("""
                                You are a helpful assistant that helps the user remember 
                                things from previously saved snippets.
                                You answer questions using only the saved snippets provided below. \
                                If the snippets don't contain a relevant answer, say so plainly \
                                rather than guessing.
                                Do not ask any follow up questions, answer as well as you can in one answer, \
                                the user cant answer back.
                                
                                You will receive snippets in the format Note: ...\\nSnippet: ...\\nSource: ...
                                where the snippet is the literal thing the user saved, note is a custom note the
                                user added and source is the name of the program the user saved from.
                                The "Note:" field is the most relevant for determining what is important for the users query.
                                If the user mentiones something in the Note: field, tell them about the Snippet and Note
                                Answer short and concise, use bold highlighting for the most important keywords.

                                Saved snippets:
                                \(contextText)
                                """),
                            .user(question)
                        ]
                    )

                    for try await chunk in stream {
                        let content = chunk.message.content
                        continuation.yield(content)
                    }
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }
}
