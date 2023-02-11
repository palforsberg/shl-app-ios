//
//  Data.swift
//  HockeyPal
//
//  Created by Pål Forsberg on 2021-01-08.
//

import Foundation
import SwiftUI

#if DEBUG
let baseUrl = "http://192.168.141.229:8080"
#else
let baseUrl = "https://palsserver.com/shl-api"
#endif
let gamesUrl = { (season: Int) -> String in return "\(baseUrl)/games/\(season)" }
let standingsUrl = { (season: Int) -> String in return "\(baseUrl)/standings/\(season)" }
let teamsUrl = "\(baseUrl)/teams?season=\(Settings.currentSeason)"
let playoffUrl = "\(baseUrl)/playoffs/\(Settings.currentSeason)"
let userUrl = "\(baseUrl)/user"
let gameStatsUrl = { (game: Game) -> String in
    return "\(baseUrl)/game/\(game.game_uuid)/\(game.game_id)"
}
let playersUrl = { (code: String) -> String in
    "\(baseUrl)/players/\(code)"
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
                print("[DATA] failed to decode cache \(error)")
                return nil
            }
        }
        return nil
    }
    
    func getKey(_ key: String) -> String {
        // to make it possible to change the datamodel between versions
        return "\(key)_v0.2.1"
    }
}

class DataProvider {
    
    private let apiJsonDecoder = getJsonDecoder()
    private let cache = Cache()

    init() {
    }

    func getGames(season: Int) async -> [Game]? {
        let url = gamesUrl(season)
        if season != Settings.currentSeason {
            if let cached = cache.retrieve(key: url, type: [Game].self) {
                return cached
            }
        }
        return await getData(url: url, type: [Game].self)
    }
    
    func getCachedGames() -> [Game] {
        return cache.retrieve(key: gamesUrl(Settings.currentSeason), type: [Game].self) ?? []
    }

    func getStandings(season: Int) async -> [Standing]? {
        let url = standingsUrl(season)
        if season != Settings.currentSeason {
            if let cached = cache.retrieve(key: url, type: [Standing].self) {
                return cached
            }
        }
        return await getData(url: standingsUrl(season), type: [Standing].self)
    }
    
    func getGameStats(game: Game) async -> GameStats? {
        return await getData(url: gameStatsUrl(game), type: GameStats.self)
    }
    
    func getTeams() async -> [Team]? {
        if let cached = cache.retrieve(key: teamsUrl, type: [Team].self) {
            return cached
        }
        return await getData(url: teamsUrl, type: [Team].self)
    }
    
    func getPlayoffs() async -> Playoffs? {
        return await getData(url: playoffUrl, type: Playoffs.self)
    }
    
    func getPlayers(for code: String) async -> [PlayerStats]? {
        return await getData(url: playersUrl(code), type: [PlayerStats].self)
    }
    
    func addUser(request: AddUser) async {
        await postData(url: userUrl, data: request)
    }

    func getData<T : Codable>(url urlString: String, type: T.Type) async -> T? {
        guard let url = URL(string: urlString) else {
            print("[DATA] Your API end point is Invalid")
            return nil
        }
        let request = URLRequest(url: url)
        print("[DATA] GET \(type) from \(url)")
        
        do {
            let (data, _) = try await URLSession.shared.data(for: request)
            let parsed = try apiJsonDecoder.decode(type, from: data)
            self.cache.store(key: urlString, data: parsed)
            return parsed
        } catch let error {
            print("[DATA] Failed to retrieve data \(error)")
            return self.cache.retrieve(key: urlString, type: type)
        }
    }
    
    func postData<T : Codable & Equatable>(url urlString: String, data: T) async {
        
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
        
        do {
            let (_, response) = try await URLSession.shared.data(for: request)
            guard let response = response as? HTTPURLResponse else {
                print("[DATA] error", response)
                return
            }
            guard response.statusCode == 200 else {
                print("[DATA] statusCode should be 200, but is \(response.statusCode)")
                return
            }
            self.cache.store(key: urlString, data: data)
        } catch {
            print("[DATA] error", error)
        }
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
        return getGames()
            .filter({ $0.isLive() })
            .filter(getTeamFilter(teamCodes: teamCodes))
    }

    func getPlayedGames(teamCodes: [String]) -> [Game] {
        return getGames()
            .sorted { (a, b) -> Bool in
                return a.start_date_time > b.start_date_time
            }
            .filter({ $0.isPlayed() })
            .filter(getTeamFilter(teamCodes: teamCodes))
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
enum GameStatus: String, Codable {
    case coming = "Coming"
    case period1 = "Period1"
    case period2 = "Period2"
    case period3 = "Period3"
    case overtime = "Overtime"
    case shootout = "Shootout"
    case finished = "Finished"
    case intermission = "Intermission"
    
    func isGameTimeApplicable() -> Bool {
        switch self {
        case .period1,
                .period2,
                .period3,
                .overtime:
            return true
        default:
            return false
        }
    }
    
    func isLive() -> Bool {
        switch self {
        case .period1,
                .period2,
                .period3,
                .overtime,
                .shootout,
                .intermission:
            return true
        default:
            return false
        }
    }
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
    let status: String?
    let gametime: String?
    
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

    func isPlayed() -> Bool {
        return getStatus() == .finished
    }
    
    func isLive() -> Bool {
        return getStatus()?.isLive() ?? false
    }
    
    func isFuture() -> Bool {
        return getStatus() == nil || getStatus() == .coming
    }
    
    func getGameType() -> GameType? {
        return GameType.init(rawValue: self.game_type)
    }

    func getStatus() -> GameStatus? {
        return self.status != nil ? GameStatus.init(rawValue: self.status!) : nil
    }

    func isPlayoff() -> Bool {
        self.game_type == "Playoff game"
    }
    
    func isDemotion() -> Bool {
        self.game_type == "Kvalmatch nedflyttning"
    }
}

class StandingsData: ObservableObject {
    public var data: [Standing]
    
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
    
    func getFor(team: String) -> Standing? {
        return self.data.first(where: { $0.team_code == team })
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
    
    func getShortname(_ code: String) -> String {
        return teams[code]?.shortname ?? code
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
    let shortname: String
}

struct GameStatsData: Codable {
    var data: GameStats
}

struct GameStats: Codable {
    var recaps: AllPeriods
    var gameState: String
    var playersByTeam: [String: TeamPlayers]?
    var status: String?
    var events: [GameEvent]?
    var report: GameReport?
    
    func getTopPlayers() -> [Player] {
        var allPlayers = [Player]()
        playersByTeam?.forEach({ (key: String, value: TeamPlayers) in
            allPlayers.append(contentsOf: value.players ?? [])
        })
        
        return Array(allPlayers
                        .filter({ p in p.getScore() > 0 })
                        .sorted(by: { p1, p2 in p1.id >= p2.id })
                        .sorted(by: { p1, p2 in p1.getScore() >= p2.getScore() })
                        .prefix(5))
    }
    
    func getStatus() -> GameStatus? {
        return self.status != nil ? GameStatus.init(rawValue: self.status!) : nil
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
    var position: String
    
    func getScore() -> Int {
        return (g * 6) + (a * 3) + (pim * 1)
    }
}


struct PlusMinus: Codable {
    var d: Int
}

struct PlayerStats: Codable, Identifiable {
    var id: String {
        return "\(player)\(firstName)\(familyName)"
    }
    var player: Int
    var team: String
    var firstName: String
    var familyName: String
    var position: String
    var jersey: Int
    var gp: Int?
    var rank: Int?

    var toi: String?
    var g: Int?
    var a: Int?
    var sog: Int?
    var pim: Int?
    var toiSeconds: Int?
    var pop: Int?
    var nep: Int?
    var pops: [PlusMinus]?
    
    // GK stats
    var tot_svs: Int?
    var tot_ga: Int?
    var tot_soga: Int?
    
    func hasPlayed() -> Bool {
        (self.gp ?? 0) > 0
    }
    
    func getScore() -> Int {
        if self.position == "GK" {
            return getGkScore()
        }
        return getPoints()
    }
    
    func getPoints() -> Int {
        (g ?? 0) + (a ?? 0)
    }

    func getImpactScore() -> Int {
        (pop ?? 0) - (nep ?? 0)
    }
    
    func getGkScore() -> Int {
        return tot_svs ?? 0
    }
    
    func getSavesPercentage() -> Float {
        return ((Float)(tot_svs ?? 0) / (Float)(tot_soga ?? 1)) * 100
    }
    
    func getGoalsPerShotPercentage() -> Float {
        return (Float(g ?? 0) / Float(max(sog ?? 1, 1))) * 100
    }
    
    func getPointsPerGame() -> Float {
        Float(getPoints()) / Float(gp ?? 0)
    }
    
    func getToiFormatted() -> String {
        PlayerStats.formatSeconds(toiSeconds ?? 0)
    }
    
    func getToiPerGame() -> Int {
        (toiSeconds ?? 0) / (gp ?? 1)
    }
    
    func getToiPerGameFormatted() -> String {
        PlayerStats.formatSeconds(getToiPerGame())
    }
    
    /*
    func getPlusMinusEntries() -> [PlusMinusEntry] {
        var total = 0
        return self.pops?
            .enumerated()
            .map({ i, e in
                total += e.d
                return PlusMinusEntry(i: i, d: total)
            })
        ?? []
    }
     */
    
    static func formatSeconds(_ seconds: Int) -> String {
        let (h, m, s) = (seconds / 3600, (seconds % 3600) / 60, (seconds % 3600) % 60)
        if h > 0 {
            return String(format: "%02d:%02d:%02d", h, m, s)
        }
        return String(format: "%02d:%02d", m, s)
    }
}

struct EventPlayer: Codable {
    var firstName: String
    var familyName: String
    var jersey: Int
}
struct GameEventInfo: Codable {
    var homeTeamId: String
    var awayTeamId: String
    var homeResult: Int
    var awayResult: Int
    
    var team: String?
    var player: EventPlayer?
    
    var isPowerPlay: Bool?
    var teamAdvantage: String?
    
    var periodNumber: Int?
    
    var penalty: Int?
    var penaltyLong: String?
    var reason: String?
    
    func getTeamAdvantage() -> String {
        if self.teamAdvantage == "EQ" {
            return ""
        }
        return self.teamAdvantage ?? ""
    }
}

enum GameEventType : String, Codable {
    case gameStart = "GameStart"
    case gameEnd = "GameEnd"
    case goal = "Goal"
    case penalty = "Penalty"
    case periodStart = "PeriodStart"
    case periodEnd = "PeriodEnd"
}

struct GameEvent: Codable, Identifiable {
    var type: String
    var info: GameEventInfo
    var timestamp: Date
    var id: String
    var gametime: String
    
    func getEventType() -> GameEventType? {
        return GameEventType(rawValue: type)
    }
}

struct GameReport: Codable {
    var gametime: String
    var timePeriod: Int
    var period: Int
    var gameState: String
}

struct AddUser: Codable, Equatable {
    var id: String
    var apn_token: String?
    var teams: [String]
    var ios_version: String?
    var app_version: String?
}


struct PlayoffEntry: Codable, Identifiable {
    var id: String {
        return "\(team1)_\(team2)"
    }
    var team1: String
    var team2: String
    var score1: UInt8
    var score2: UInt8
}

struct Playoffs: Codable {
    var demotion: PlayoffEntry?
    var eight: [PlayoffEntry]?
    var quarter: [PlayoffEntry]?
    var semi: [PlayoffEntry]?
    var final: PlayoffEntry?
}

class PlayoffData: ObservableObject {
    var data: Playoffs?
    
    func setData(_ data: Playoffs?) {
        self.data = data
        self.objectWillChange.send()
    }
}

func getJsonDecoder() -> JSONDecoder {
    let jsonDecoder = JSONDecoder()
    let isoDateFormatter = ISO8601DateFormatter()
    jsonDecoder.dateDecodingStrategy = JSONDecoder.DateDecodingStrategy.custom({ (decoder) -> Date in
        let container = try decoder.singleValueContainer()
        var dateStr = try container.decode(String.self)
        if dateStr.contains(".") {
            dateStr = dateStr.replacingOccurrences(of: "\\.\\d+", with: "", options: .regularExpression)
        }
        return isoDateFormatter.date(from: dateStr)!
    })
    return jsonDecoder
}

struct RuntimeError: Error {
    let message: String

    init(_ message: String) {
        self.message = message
    }

    public var localizedDescription: String {
        return message
    }
}
