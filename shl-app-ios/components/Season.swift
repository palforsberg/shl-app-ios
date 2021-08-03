//
//  Season.swift
//  shl-app-ios
//
//  Created by Pål on 2021-08-03.
//

import Foundation


class Season: ObservableObject {
    
    static let currentSeason = 2021
    @Published var season: Int
    
    init() {
        self.season = Season.currentSeason
    }

    func getFormatted() -> String {
        return "\(Season.getFormatted(season: season).suffix(5))"
    }
    
    func getLongFormatted() -> String {
        return "\(Season.getFormatted(season: season))"
    }
    
    func getFormattedPrevSeason() -> String {
        guard season != Season.currentSeason else {
            return ""
        }
        return getFormatted()
    }

    static func getFormatted(season: Int) -> String {
        let next = String(season + 1)
        
        return "\(season)/\(next.suffix(2))"
    }
    
    func set(_ season: Int) {
        self.season = season
    }
}
