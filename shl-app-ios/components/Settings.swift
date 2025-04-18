//
//  Settings.swift
//  shl-app-ios
//
//  Created by Pål on 2021-08-09.
//

import Foundation

extension KeyPath where Root == Settings {
    var stringValue: String {
        switch self {
            case \Settings.onlyStarred: return "onlyStarred"
            case \Settings.notificationsEnabled: return "notificationsEnabled"
            case \Settings.supporter: return "supporter"
            case \Settings.apnToken: return "apnToken"
            case \Settings.uuid: return "uuid"
            default: return "unknown"
        }
    }
}
    
class Settings: ObservableObject {
    
    static let currentSeason = 2024
    @Published var season: Int

    @Published var apnToken: String? {
        didSet {
            store(\.apnToken)
        }
    }
    
    @Published var onlyStarred: Bool {
        didSet {
            store(\.onlyStarred)
        }
    }

    @Published var notificationsEnabled: Bool {
        didSet {
            store(\.notificationsEnabled)
        }
    }
    @Published var supporter: Bool {
        didSet {
            store(\.supporter)
        }
    }
    var uuid: String {
        didSet {
            store(\.uuid)
        }
    }
    
    init() {
        season = Settings.currentSeason
        apnToken = UserDefaults.standard.object(forKey: Settings.getkey(\.apnToken)) as? String
        onlyStarred = Settings.read(\.onlyStarred, orDefault: true)
        notificationsEnabled = Settings.read(\.notificationsEnabled, orDefault: false)
        supporter = Settings.read(\.supporter, orDefault: false)
        if let _uuid = UserDefaults.standard.object(forKey: Settings.getkey(\.uuid)) as? String {
            uuid = _uuid
        } else {
            uuid = UUID().uuidString
            store(\.uuid)
        }
    }
    
    func getFormattedSeason() -> String {
        return "\(Settings.getFormatted(season: season).suffix(5))"
    }
    
    func getFormattedPrevSeason() -> String {
        guard season != Settings.currentSeason else {
            return ""
        }
        return getFormattedSeason()
    }

    static func getFormatted(season: Int) -> String {
        let next = String(season + 1)
        
        return "\(season)/\(next.suffix(2))"
    }
    
    private static func read<T>(_ key: KeyPath<Settings, T>, orDefault: T) -> T {
        let value = UserDefaults.standard.object(forKey: Settings.getkey(key))
        return value as? T ?? orDefault
    }
    
    private func store<T>(_ key: KeyPath<Settings, T?>) {
        if self[keyPath: key] == nil {
            print("[SETTINGS] remove value \(Settings.getkey(key))" )
            UserDefaults.standard.removeObject(forKey: Settings.getkey(key))
        } else {
            print("[SETTINGS] set value \(Settings.getkey(key)) to \(self[keyPath: key]!)" )
            UserDefaults.standard.setValue(self[keyPath: key], forKey: Settings.getkey(key))
        }
        UserDefaults.standard.synchronize()
    }
    
    private func store<T>(_ key: KeyPath<Settings, T>) {
        print("[SETTINGS] set value \(Settings.getkey(key)) to \(self[keyPath: key])" )
        UserDefaults.standard.setValue(self[keyPath: key], forKey: Settings.getkey(key))
        UserDefaults.standard.synchronize()
    }
    
    private static func getkey<T>(_ key: KeyPath<Settings, T>) -> String {
        return "settings_\(key.stringValue)"
    }
}
