//
//  Cache.swift
//  shl-app-ios
//
//  Created by Pål on 2023-02-14.
//

import Foundation

extension String {
    var sanitizedFileName: String {
        return components(separatedBy: .init(charactersIn: "/\\:\\?%*|\"<>")).joined()
    }
}

class Cache {
    static var encoder = JSONEncoder()
    static var decoder = JSONDecoder()
    
    static func store<T : Codable>(key: String, data: T) {
        let keyPath = getKey(key).sanitizedFileName
        do {
            let json = try encoder.encode(data)
            let url = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.palforsberg.shl-app-ios")?.appendingPathComponent(keyPath)
            try json.write(to: url!)
        } catch {
            print("[DATA] failed to encode cache \(keyPath) \(error)")
        }
    }
    
    static func retrieve<T: Codable>(key: String, type: T.Type) -> T? {
        let keyPath = getKey(key).sanitizedFileName
        let url = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.palforsberg.shl-app-ios")?.appendingPathComponent(keyPath)
        if let archived = try? Data(contentsOf: url!){
            print("[CACHE] GET cached \(type) from \(keyPath)")
            do {
                return try decoder.decode(type.self, from: archived)
            } catch {
                print("[DATA] failed to decode cache \(keyPath) \(error)")
                return nil
            }
        }
        return nil
    }
    
    static func clearOld() {
        let currentKey = Cache.getKey("")
        print("[CACHE] Clear old, new key \(currentKey)")
        UserDefaults.shared.dictionaryRepresentation().keys
            .filter { $0.starts(with: "http") && !$0.contains(currentKey) }
            .forEach { cacheKey in
                print("[CACHE] Remove key \(cacheKey)")
                UserDefaults.shared.removeObject(forKey: cacheKey)
            }
    }
    
    static func getKey(_ key: String) -> String {
        // to make it possible to change the datamodel between versions
        return "\(key)_v\(Cache.getBuildVersionNumber() ?? "unknown")"
    }
    
    static func getBuildVersionNumber() -> String? {
        return Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
    }
}
