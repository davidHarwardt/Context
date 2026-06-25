//
//  AppSecureStorage.swift
//  Context
//
//  Created by David Harwardt on 24.06.26.
//

import SwiftUI
import Foundation
import KeychainSwift

@propertyWrapper
public struct AppSecureStorage: DynamicProperty {
    private let key: String
    private let access: KeychainSwiftAccessOptions
    
    private let keychain = KeychainSwift(keyPrefix: "contextSecureWrapper_")
    
    @Observable
    fileprivate class Trigger {
        public var stateUpdate: Bool = false
    }
    
    @State private var trigger = Trigger()
    
    public var wrappedValue: String? {
        get {
            _ = trigger.stateUpdate
            return keychain.get(key)
        }
        nonmutating set {
            if newValue != nil && !newValue!.isEmpty {
                keychain.set(newValue!, forKey: key)
            } else {
                keychain.delete(key)
            }
            trigger.stateUpdate.toggle()
        }
    }
    
    public var projectedValue: Binding<String?> {
        Binding(
            get: { self.wrappedValue },
            set: { self.wrappedValue = $0 }
        )
    }
    
    public init(_ key: String, access: KeychainSwiftAccessOptions = .accessibleWhenUnlocked) {
        self.key = key
        self.access = access
    }
}

extension Binding where Value == String {
    init(_ source: Binding<String?>, replacingNilWith defaultValue: String) {
        self.init(
            get: { source.wrappedValue ?? defaultValue },
            set: { source.wrappedValue = $0 }
        )
    }
}
