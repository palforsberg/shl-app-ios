//
//  Cache.swift
//  shl-app-ios
//
//  Created by Pål on 2023-02-14.
//

import Foundation

class Cache {
    static var storage = UserDefaults.shared
    static var encoder = JSONEncoder()
    static var decoder = JSONDecoder()
    
    static func store<T : Codable>(key: String, data: T) {
        do {
            let json = try encoder.encode(data)
            storage.set(json, forKey: getKey(key))
            storage.synchronize()
        } catch {
            print("[DATA] failed to encode cache \(error)")
        }
    }
    
    static func retrieve<T: Codable>(key: String, type: T.Type) -> T? {
        if let archived = storage.object(forKey: getKey(key)) as? Data {
            print("[CACHE] GET cached \(type) from \(getKey(key))")
            do {
                return try decoder.decode(type.self, from: archived)
            } catch {
                print("[DATA] failed to decode cache \(error)")
                return nil
            }
        }
        return nil
    }
    
    static func getKey(_ key: String) -> String {
        // to make it possible to change the datamodel between versions
        return "\(key)_v0.3.0"
    }
}
