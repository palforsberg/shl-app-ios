//
//  Data.swift
//  HockeyPal
//
//  Created by Pål Forsberg on 2021-01-08.
//

import Foundation
import SwiftUI

let season = 2021
let baseUrl = "http://86.107.103.138/shl-api"
let gamesUrl = "\(baseUrl)/games/\(season)"
let standingsUrl = "\(baseUrl)/standings/\(season)"
let teamsUrl = "\(baseUrl)/teams"
let gameStatsUrl = { (game: Game) -> String in
    return "\(baseUrl)/game/\(game.game_uuid)/\(game.game_id)"
}

class Cache {
    var storage = UserDefaults.standard
    var encoder = JSONEncoder()
    var decoder = JSONDecoder()
    
    func store<T : Codable>(key: String, data: T) {
        if let json = try? encoder.encode(data) {
            storage.set(json, forKey: key)
            storage.synchronize()
        }
    }
    
    func retrieve<T: Codable>(key: String, type: T.Type) -> T? {
        if let archived = storage.object(forKey: key) as? Data {
            return try! decoder.decode(type.self, from: archived)
        }
        return nil
    }
}

class DataProvider {
    
    private let cache = Cache()
    let decoder = JSONDecoder()

    init() {
        decoder.dateDecodingStrategy = JSONDecoder.DateDecodingStrategy.iso8601
    }

    func getGames(completion: @escaping ([Game]) -> ()) {
        getData(url: gamesUrl, type: [Game].self, completion: { (e: [Game]) -> () in
            completion(e)
        })
    }

    func getStandings(completion: @escaping (StandingsData) -> ()) {
        getData(url: standingsUrl, type: [Standing].self, completion: { (e: [Standing]) -> () in
            completion(StandingsData(data: e))
        })
    }
    
    func getGameStats(game: Game, completion: @escaping (GameStats) -> ()) {
        getData(url: gameStatsUrl(game), type: GameStats.self, completion: completion)
    }
    
    func getTeams(completion: @escaping ([Team]) -> ()) {
        getData(url: teamsUrl, type: [Team].self, completion: completion)
    }

    func getData<T : Codable>(url: String, type: T.Type, completion: @escaping (T) -> ()) {
        guard let url = URL(string: url) else {
            print("Your API end point is Invalid")
            return
        }
        let cacheKey = url.relativePath
        let request = URLRequest(url: url)
        print("fetching \(type) from \(url)")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let data = data {
                do {
                    let decoder = JSONDecoder()
                    decoder.dateDecodingStrategy = JSONDecoder.DateDecodingStrategy.iso8601
                    let response = try decoder.decode(type, from: data)
                    self.cache.store(key: cacheKey, data: response)
                    DispatchQueue.main.async {
                        completion(response)
                    }
                } catch let error {
                    print("error \(error.localizedDescription)")
                    DispatchQueue.main.async {
                        if let cached = self.cache.retrieve(key: cacheKey, type: type) {
                            completion(cached)
                        }
                    }
                }
            } else if let error = error {
                print("error \(error.localizedDescription)")
                DispatchQueue.main.async {
                    if let cached = self.cache.retrieve(key: cacheKey, type: type) {
                        completion(cached)
                    }
                }
            }
        }.resume()
    }
}

class GamesData: ObservableObject {
    @Published var data: [Game]
    
    init(data: [Game]) {
        self.data = data
    }
    
    func getGames() -> [Game] {
        return data.sorted { (a, b) -> Bool in
            return a.start_date_time < b.start_date_time
        }
    }

    func getLiveGames(teamCodes: [String]) -> [Game] {
        return Array(getGames()
                        .filter({ $0.isLive() })
                        .filter(getTeamFilter(teamCodes: teamCodes)))
    }
    
    func getPlayedGames(teamCodes: [String]) -> [Game] {
        return Array(getGames()
            .sorted { (a, b) -> Bool in
                return a.start_date_time > b.start_date_time
            }
            .filter({ $0.isPlayed() })
            .filter(getTeamFilter(teamCodes: teamCodes)))
    }
    
    func getFutureGames(teamCodes: [String]) -> [Game] {
        return Array(getGames()
                        .filter({ $0.isFuture() })
                        .filter(getTeamFilter(teamCodes: teamCodes))
                        .prefix(5))
    }
    
    func getTeamFilter(teamCodes: [String]) -> (Game) -> Bool {
        if (teamCodes.isEmpty) {
            return { game in return true }
        }
        
        return { game in teamCodes.contains { (e) -> Bool in
            return game.hasTeam(e)
        }}
    }
    
    func getGamesBetween(team1: String, team2: String) -> [Game] {
        return getPlayedGames(teamCodes: []).filter { g in
            return g.hasTeam(team1) && g.hasTeam(team2)
        }
    }
}

struct Game: Codable, Identifiable  {
    var id: Int {
        return game_id
    }
    let game_id: Int
    let game_uuid: String
    let away_team_code: String
    let away_team_result: Int
    let home_team_code: String
    let home_team_result: Int
    let start_date_time: Date
    let played: Bool
    
    func hasTeam(_ teamCode: String) -> Bool {
        return away_team_code == teamCode || home_team_code == teamCode
    }
    
    func isHome(_ teamCode: String) -> Bool {
        return teamCode == home_team_code
    }
    
    func homeWon() -> Bool {
        return home_team_result > away_team_result
    }
    
    func didWin(_ teamCode: String) -> Bool {
        if (isHome(teamCode)) {
            return homeWon()
        }
        return !homeWon()
    }
    
    func isPlayed() -> Bool {
        return played
    }
    
    func isLive() -> Bool {
        return start_date_time < Date() && played == false
    }
    
    func isFuture() -> Bool {
        return start_date_time > Date()
    }
}

struct StandingsData: Codable {
    let data: [Standing]
}

struct Standing: Codable, Identifiable {
    var id: String {
        return team_code
    }
    let team_code: String
    let gp: Int
    let rank: Int
    let points: Int
    
    func getPointsPerGame() -> String {
        if (gp == 0) {
            return "0.0"
        }
        return String(format: "%.1f", Double(points) / Double(gp))
    }
}

class TeamsData: ObservableObject {
    @Published var teams = [String:Team]()
    
    func getTeam(_ code: String) -> Team? {
        return teams[code]
    }
    
    func getName(_ code: String) -> String {
        return teams[code]?.name ?? code
    }

    func setTeams(teams: [Team]) {
        for team in teams {
            self.teams[team.code] = team
        }
    }
}

struct Team: Codable {
    let code: String
    let name: String
}

struct GameStatsData: Codable {
    var data: GameStats
}

struct GameStats: Codable {
    var recaps: AllPeriods
    var gameState: String
}

struct AllPeriods: Codable {
    var gameRecap: Period?
    var period1: Period?
    var period2: Period?
    var period3: Period?
    var period4: Period?
    var period5: Period?
    
    private enum CodingKeys : String, CodingKey {
        case gameRecap, period1 = "0", period2 = "1", period3 = "2", period4 = "3", period5 = "4"
    }
}

struct Period: Codable {
    var periodNumber: Int8
    var homeG: Int16
    var awayG: Int16
    var homeHits: Int16
    var homeSOG: Int16
    var homePIM: Int16
    var homeFOW: Int16
    var awayHits: Int16
    var awaySOG: Int16
    var awayPIM: Int16
    var awayFOW: Int16
}


extension Date {
   func getFormattedDateAndTime() -> String {
        let dateformat = DateFormatter()
        
        dateformat.locale = Locale.current
        let dateDelta = Date.daysBetween(from: Date(), to: self)
    
        if (dateDelta < 1) {
            dateformat.doesRelativeDateFormatting = true
            dateformat.dateStyle = .short
            dateformat.timeStyle = .short
        } else if (dateDelta < 7) {
            dateformat.dateFormat = "E HH:mm"
        } else {
            dateformat.dateFormat = "dd/MM HH:mm"
        }
        return dateformat.string(from: self)
    }
    
    func getFormattedDate() -> String {
         let dateformat = DateFormatter()
         
         dateformat.locale = Locale.current
         let dateDelta = Date.daysBetween(from: Date(), to: self)
     
         if (dateDelta < 1) {
             dateformat.doesRelativeDateFormatting = true
             dateformat.dateStyle = .short
         } else if (dateDelta < 7) {
             dateformat.dateFormat = "E"
         } else {
             dateformat.dateFormat = "dd/MM"
         }
         return dateformat.string(from: self)
     }
    
    
    func getFormattedTime() -> String {
        let dateformat = DateFormatter()
        dateformat.locale = Locale.current
        dateformat.dateFormat = "HH:mm"
        return dateformat.string(from: self)
     }
    
    static func daysBetween(from: Date, to: Date) -> Int {
        return Calendar.current.dateComponents([.day], from: from, to: to).day!
    }
}
