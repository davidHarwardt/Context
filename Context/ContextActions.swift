//
//  Context.swift
//  Context
//
//  Created by David Harwardt on 24.06.26.
//

import Foundation
import Ollama
import CoreGraphics

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

public final class ContextActions {
    var client: Client
    
    init() {
        self.client = Client.default
    }
    
    func addContext(
        prompt: String,
        data: ContextData? = nil,
    ) {
        
    }
}
