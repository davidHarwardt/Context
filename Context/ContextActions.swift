//
//  Context.swift
//  Context
//
//  Created by David Harwardt on 24.06.26.
//

import Foundation
import Ollama
import CoreGraphics
import VecturaKit
import VecturaNLKit
internal import AppKit

/// Smaller models
/// - ollama run qwen3:8b
/// Larger models:
/// - qwen3:30b-a3b
/// - hermes4:14b
/// Vision models:
/// - qwen2.5-vl:7b

public enum ContextData {
    case image(CGImage)
    case file(URL)
}

public struct ContextMatch: Identifiable, Sendable {
    public let id: UUID
    public let text: String
    public let score: Float
    public let createdAt: Date
}

@MainActor
@Observable
public final class ContextActions {
    private var client: Client
    private let chatModel: Model.ID = "qwen3:8b"
    private let visionModel: Model.ID = "qwen2.5-vl:7b"
    private let ragStoreTask: Task<VecturaKit, Error>
    private var messages: [Chat.Message] = [
        .system("""
        You are a helpful assistant directly integrated into the user's Mac operating system.
        Answer concisely and use any provided screenshots, files, notes, and retrieved context as grounding.
        When retrieved context documents are relevant, mention the matching document IDs and connect related ideas across them.
        """)
    ]

    public private(set) var isResponding = false
    public private(set) var lastQuestion: String = ""
    public private(set) var lastAnswer: String = ""
    public private(set) var lastError: String?
    public private(set) var lastRelevantDocuments: [ContextMatch] = []

    init() {
        self.client = Self.makeOllamaClient(host: AppState.defaultOllamaHost, apiKey: "")
        self.ragStoreTask = Self.makeRAGStoreTask()
    }

    init(ollamaHost: String, apiKey: String) {
        self.client = Self.makeOllamaClient(host: ollamaHost, apiKey: apiKey)
        self.ragStoreTask = Self.makeRAGStoreTask()
    }

    init(client: Client) {
        self.client = client
        self.ragStoreTask = Self.makeRAGStoreTask()
    }

    func configureOllama(host: String, apiKey: String) {
        self.client = Self.makeOllamaClient(host: host, apiKey: apiKey)
    }

    func ask(_ prompt: String) {
        let trimmedPrompt = prompt.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedPrompt.isEmpty else { return }

        send(prompt: trimmedPrompt, data: nil)
    }

    func addContext(
        _ prompt: String,
        data: ContextData? = nil
    ) {
        let trimmedPrompt = prompt.trimmingCharacters(in: .whitespacesAndNewlines)
        let contextPrompt = trimmedPrompt.isEmpty ? "Use this as context for the next answer." : trimmedPrompt

        send(prompt: contextPrompt, data: data)
    }

    private func send(prompt: String, data: ContextData?) {
        isResponding = true
        lastError = nil

        Task { [weak self] in
            guard let self else { return }

            do {
                let relevantDocuments = try await relevantDocuments(for: prompt)
                lastRelevantDocuments = relevantDocuments

                let userMessage = try makeUserMessage(
                    prompt: prompt,
                    data: data,
                    relevantDocuments: relevantDocuments
                )
                messages.append(userMessage)

                let response = try await client.chat(
                    model: data == nil ? chatModel : visionModel,
                    messages: messages,
                    think: false
                )

                messages.append(response.message)
                lastAnswer = response.message.content
                try await storeInteraction(
                    prompt: prompt,
                    data: data,
                    relevantDocuments: relevantDocuments,
                    answer: response.message.content
                )
                print("ollama: \(response.message.content)")
            } catch {
                lastError = error.localizedDescription
                print("ollama error: \(error)")
            }

            isResponding = false
        }
    }

    private func makeUserMessage(
        prompt: String,
        data: ContextData?,
        relevantDocuments: [ContextMatch]
    ) throws -> Chat.Message {
        let augmentedPrompt = promptWithRelevantContext(prompt, relevantDocuments: relevantDocuments)

        switch data {
        case .image(let image):
            guard let pngData = pngData(from: image) else {
                throw ContextActionError.couldNotEncodeImage
            }
            return .user(augmentedPrompt, images: [pngData])
        case .file(let url):
            return .user(filePrompt(augmentedPrompt, fileURL: url))
        case nil:
            return .user(augmentedPrompt)
        }
    }

    private func relevantDocuments(for prompt: String) async throws -> [ContextMatch] {
        do {
            let ragStore = try await ragStoreTask.value
            let results = try await ragStore.search(
                query: .text(prompt),
                numResults: 5,
                threshold: 0.08
            )
            return results.map {
                ContextMatch(
                    id: $0.id,
                    text: $0.text,
                    score: $0.score,
                    createdAt: $0.createdAt
                )
            }
        } catch {
            print("rag retrieval error: \(error)")
            return []
        }
    }

    private func storeInteraction(
        prompt: String,
        data: ContextData?,
        relevantDocuments: [ContextMatch],
        answer: String
    ) async throws {
        let documentText = storedDocumentText(
            prompt: prompt,
            data: data,
            relevantDocuments: relevantDocuments,
            answer: answer
        )
        let trimmedDocumentText = documentText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedDocumentText.isEmpty else { return }

        do {
            let ragStore = try await ragStoreTask.value
            let id = try await ragStore.addDocument(text: trimmedDocumentText)
            print("rag stored document: \(id)")
        } catch {
            print("rag storage error: \(error)")
        }
    }

    private func promptWithRelevantContext(
        _ prompt: String,
        relevantDocuments: [ContextMatch]
    ) -> String {
        guard !relevantDocuments.isEmpty else { return prompt }

        return """
        User request:
        \(prompt)

        Relevant context documents:
        \(formattedRelevantDocuments(relevantDocuments))

        Use the relevant context to answer the user. Point out matching document IDs when they help, and connect related ideas across documents instead of treating each match in isolation.
        """
    }

    private func storedDocumentText(
        prompt: String,
        data: ContextData?,
        relevantDocuments: [ContextMatch],
        answer: String
    ) -> String {
        let contextSummary: String
        switch data {
        case .image:
            contextSummary = "Context type: screenshot image"
        case .file(let url):
            contextSummary = filePrompt("Context type: file", fileURL: url)
        case nil:
            contextSummary = "Context type: text prompt"
        }

        return """
        Prompt:
        \(prompt)

        \(contextSummary)

        Matched prior context:
        \(formattedRelevantDocuments(relevantDocuments))

        Answer:
        \(answer)
        """
    }

    private func formattedRelevantDocuments(_ documents: [ContextMatch]) -> String {
        guard !documents.isEmpty else { return "None" }

        return documents.enumerated().map { index, document in
            """
            [\(index + 1)] id=\(document.id.uuidString) score=\(String(format: "%.3f", document.score)) created=\(document.createdAt.formatted(date: .abbreviated, time: .shortened))
            \(document.text.prefix(1200))
            """
        }.joined(separator: "\n\n")
    }

    private func pngData(from image: CGImage) -> Data? {
        let bitmap = NSBitmapImageRep(cgImage: image)
        return bitmap.representation(using: .png, properties: [:])
    }

    private func filePrompt(_ prompt: String, fileURL: URL) -> String {
        if fileURL.pathExtension.lowercased() == "pdf",
           let text = DocumentParser().extractTextFromPDF(at: fileURL) {
            return """
            \(prompt)

            File: \(fileURL.lastPathComponent)
            \(text)
            """
        }

        return """
        \(prompt)

        File: \(fileURL.lastPathComponent)
        """
    }

    private static func makeOllamaClient(host: String, apiKey: String) -> Client {
        let trimmedHost = host.trimmingCharacters(in: .whitespacesAndNewlines)
        let url = URL(string: trimmedHost.isEmpty ? AppState.defaultOllamaHost : trimmedHost) ?? Client.defaultHost
        let trimmedAPIKey = apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
        let configuration = URLSessionConfiguration.default

        if !trimmedAPIKey.isEmpty {
            configuration.httpAdditionalHeaders = ["Authorization": "Bearer \(trimmedAPIKey)"]
        }

        return Client(session: URLSession(configuration: configuration), host: url)
    }

    private static func makeRAGStoreTask() -> Task<VecturaKit, Error> {
        Task {
            let embedder = try await NLContextualEmbedder()
            let config = try VecturaConfig(
                name: "ContextRAG",
                directoryURL: ragStorageDirectory(),
                searchOptions: .init(
                    defaultNumResults: 5,
                    minThreshold: 0.08,
                    hybridWeight: 0.45
                ),
                memoryStrategy: .automatic()
            )
            return try await VecturaKit(config: config, embedder: embedder)
        }
    }

    private static func ragStorageDirectory() throws -> URL {
        guard let applicationSupportURL = FileManager.default.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        ).first else {
            throw ContextActionError.couldNotCreateRAGStore
        }

        let directory = applicationSupportURL.appending(path: "Context")
        try FileManager.default.createDirectory(
            at: directory,
            withIntermediateDirectories: true,
            attributes: [.posixPermissions: 0o700]
        )
        return directory
    }
}

enum ContextActionError: LocalizedError {
    case couldNotEncodeImage
    case couldNotCreateRAGStore

    var errorDescription: String? {
        switch self {
        case .couldNotEncodeImage:
            "Could not encode screenshot image."
        case .couldNotCreateRAGStore:
            "Could not create the local RAG context store."
        }
    }
}
