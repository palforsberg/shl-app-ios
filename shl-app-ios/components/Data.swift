//
//  Data.swift
//  HockeyPal
//
//  Created by Pål Forsberg on 2021-01-08.
//

import Foundation
import SwiftUI

//#if DEBUG
//let baseUrl = "http://192.168.141.229:8080"
//#else
let baseUrl = "https://palsserver.com/shl-api"
//#endif
let gamesUrl = { (season: Int) -> String in return "\(baseUrl)/games/\(season)" }
let standingsUrl = { (season: Int) -> String in return "\(baseUrl)/standings/\(season)" }
let teamsUrl = "\(baseUrl)/teams?season=\(Settings.currentSeason)"
let userUrl = "\(baseUrl)/user"
let gameStatsUrl = { (game: Game) -> String in
    return "\(baseUrl)/game/\(game.game_uuid)/\(game.game_id)"
}

class Cache {
    var storage = UserDefaults.standard
    var encoder = JSONEncoder()
    var decoder = JSONDecoder()
    
    func store<T : Codable>(key: String, data: T) {
        if let json = try? encoder.encode(data) {
            storage.set(json, forKey: getKey(key))
            storage.synchronize()
        }
    }
    
    func retrieve<T: Codable>(key: String, type: T.Type) -> T? {
        if let archived = storage.object(forKey: getKey(key)) as? Data {
            print("[CACHE] GET cached \(type) from \(getKey(key))")
            do {
                return try decoder.decode(type.self, from: archived)
            } catch {
                print("[DATA] failed to decode cache \(error.localizedDescription)")
                return nil
            }
        }
        return nil
    }
    
    func getKey(_ key: String) -> String {
        // to make it possible to change the datamodel between versions
        return "\(key)_v0.1.1"
    }
}

class DataProvider {
    
    private let cache = Cache()
    let decoder = JSONDecoder()

    init() {
        decoder.dateDecodingStrategy = JSONDecoder.DateDecodingStrategy.iso8601
    }

    func getGames(season: Int, completion: @escaping ([Game]) -> ()) {
        let url = gamesUrl(season)
        if season != Settings.currentSeason {
            if let cached = cache.retrieve(key: url, type: [Game].self) {
                completion(cached)
                return
            }
        }
        getData(url: url, type: [Game].self, completion: { (e: [Game]) -> () in
            completion(e)
        })
    }

    func getStandings(season: Int, completion: @escaping ([Standing]) -> ()) {
        let url = standingsUrl(season)
        if season != Settings.currentSeason {
            if let cached = cache.retrieve(key: url, type: [Standing].self) {
                completion(cached)
                return
            }
        }
        getData(url: standingsUrl(season), type: [Standing].self, completion: completion)
    }
    
    func getGameStats(game: Game, completion: @escaping (GameStats) -> ()) {
        getData(url: gameStatsUrl(game), type: GameStats.self, completion: completion)
    }
    
    func getTeams(completion: @escaping ([Team]) -> ()) {
        if let cached = cache.retrieve(key: teamsUrl, type: [Team].self) {
            completion(cached)
            return
        }
        getData(url: teamsUrl, type: [Team].self, completion: completion)
    }
    
    func addUser(request: AddUser, completion: @escaping () -> ()) {
        postData(url: userUrl, data: request, completion: completion)
    }

    func getData<T : Codable>(url urlString: String, type: T.Type, completion: @escaping (T) -> ()) {
        guard let url = URL(string: urlString) else {
            print("[DATA] Your API end point is Invalid")
            return
        }
        let request = URLRequest(url: url)
        print("[DATA] GET \(type) from \(url)")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let data = data {
                do {
                    let decoder = JSONDecoder()
                    decoder.dateDecodingStrategy = JSONDecoder.DateDecodingStrategy.iso8601
                    let response = try decoder.decode(type, from: data)
                    self.cache.store(key: urlString, data: response)
                    DispatchQueue.main.async {
                        completion(response)
                    }
                } catch let error {
                    print("[DATA] Failed to decode JSON \(error)")
                    DispatchQueue.main.async {
                        if let cached = self.cache.retrieve(key: urlString, type: type) {
                            completion(cached)
                        }
                    }
                }
            } else if let error = error {
                print("[DATA] Failed to retrieve data \(error.localizedDescription)")
                DispatchQueue.main.async {
                    if let cached = self.cache.retrieve(key: urlString, type: type) {
                        completion(cached)
                    }
                }
            }
        }.resume()
    }
    
    func postData<T : Codable & Equatable>(url urlString: String, data: T, completion: @escaping () -> ()) {
        
        guard isNewRequest(data, key: urlString) else {
            print("[DATA] Idempotent \(type(of: data)) Request")
            return
        }
        guard let url = URL(string: urlString) else {
            print("[DATA] Your API end point is Invalid")
            return
        }
        print("[DATA] POST \(data) to \(url)")
        
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = try! JSONEncoder().encode(data)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        URLSession.shared.dataTask(with: request) { rspData, response, error in
            guard let response = response as? HTTPURLResponse,
                error == nil else {
                print("[DATA] error", error ?? "Unknown error")
                return
            }
            guard response.statusCode == 200 else {
                print("[DATA] statusCode should be 200, but is \(response.statusCode)")
                return
            }
            self.cache.store(key: urlString, data: data)
            completion()
        }.resume()
    }
    
    func isNewRequest<T: Codable & Equatable>(_ req: T, key: String) -> Bool {
        guard let lastRequest = cache.retrieve(key: key, type: T.self) else {
            return true
        }
        return lastRequest != req
    }
}

class GamesData: ObservableObject {
    private var data: [Game]
    
    init(data: [Game]) {
        self.data = data
    }
    
    func set(data: [Game]) {
        self.data = data
        self.objectWillChange.send()
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

enum GameType: String, Codable {
    case playoff = "Playoff game"
    case season = "Regular season game"
    case kvalmatch = "Kvalmatch nedflyttning"
}
struct Game: Codable, Identifiable, Equatable  {
    var id: String {
        return game_uuid
    }
    let game_id: Int
    let game_uuid: String
    let away_team_code: String
    let away_team_result: Int
    let home_team_code: String
    let home_team_result: Int
    let start_date_time: Date
    let game_type: String
    let played: Bool
    let overtime: Bool
    let penalty_shots: Bool
    
    func hasTeam(_ teamCode: String) -> Bool {
        return away_team_code == teamCode || home_team_code == teamCode
    }
    
    func isHome(_ teamCode: String) -> Bool {
        return teamCode == home_team_code
    }
    
    func homeWon() -> Bool {
        return played && home_team_result > away_team_result
    }
    
    func didWin(_ teamCode: String) -> Bool {
        if (isHome(teamCode)) {
            return homeWon()
        }
        return !homeWon()
    }
    
    func didFinishedInOt() -> Bool {
        return self.overtime || self.penalty_shots
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
    
    func getGameType() -> GameType? {
        return GameType.init(rawValue: self.game_type)
    }
}

class StandingsData: ObservableObject {
    private var data: [Standing]
    
    init(data: [Standing]) {
        self.data = data
    }
    
    func get() -> [Standing] {
        return data
    }

    func set(data: [Standing]) {
        self.data = data
        self.objectWillChange.send()
    }
}

struct Standing: Codable, Identifiable {
    var id: String {
        return team_code
    }
    let team_code: String
    let gp: Int
    let rank: Int
    let points: Int
    let diff: Int
    
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
    var playersByTeam: [String: TeamPlayers]?
    
    func getPeriodNr() -> String? {
        if gameState == "GameEnded" {
            return "Game ended"
        }
        if recaps.period4 != nil {
            return "Overtime"
        } else if recaps.period3 != nil {
            return "Period 3"
        } else if recaps.period2 != nil {
            return "Period 2"
        } else if recaps.period1 != nil {
            return "Period 1"
        }
        return nil
    }
    
    func getTopPlayers() -> [Player] {
        var allPlayers = [Player]()
        playersByTeam?.forEach({ (key: String, value: TeamPlayers) in
            allPlayers.append(contentsOf: value.players ?? [])
        })
        
        return Array(allPlayers
                        .filter({ p in p.getScore() > 0 })
                        .sorted(by: { p1, p2 in p1.getScore() >= p2.getScore() })
                        .prefix(5))
    }
}

struct TeamPlayers: Codable {
    var players: [Player]?
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
    var homeG: Int
    var awayG: Int
    var homeHits: Int
    var homeSOG: Int
    var homePIM: Int
    var homeFOW: Int
    var awayHits: Int
    var awaySOG: Int
    var awayPIM: Int
    var awayFOW: Int
}

struct Player: Codable, Identifiable {
    var id: String {
        return "\(player)\(firstName)\(familyName)"
    }
    var player: Int
    var team: String
    var firstName: String
    var familyName: String
    var toi: String
    var jersey: Int
    var g: Int
    var a: Int
    var pim: Int
    
    func getScore() -> Int {
        return (g * 6) + (a * 3) + (pim * 1)
    }
}

struct AddUser: Codable, Equatable {
    var id: String
    var apn_token: String?
    var teams: [String]
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
