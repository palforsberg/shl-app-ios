//
//  WidgetModels.swift
//  shl-app-ios
//
//  Created by Pål on 2023-02-13.
//

import Foundation
import ActivityKit


struct LiveActivityReport: Codable, Hashable {
    var homeScore: Int
    var awayScore: Int
    var status: String?
    var gametime: String?
}

struct LiveActivityEvent: Codable, Hashable {
    var title: String
    var body: String?
    var teamCode: String?
}

struct ShlWidgetAttributes: ActivityAttributes {    
    public struct ContentState: Codable, Hashable {
        // Dynamic stateful properties about your activity go here!
        var report: LiveActivityReport
        var event: LiveActivityEvent?
        
        func getStatus() -> GameStatus? {
            if let e = self.report.status {
                return GameStatus(rawValue: e)
            }
            return nil
        }
        
        static func from(_ game: Game) -> ContentState {
            ContentState(report: LiveActivityReport(homeScore: game.home_team_result, awayScore: game.away_team_result, status: game.status, gametime: game.gametime))
        }
    }

    // Fixed non-changing properties about your activity go here!
    var homeTeam: String
    var awayTeam: String
    var gameUuid: String
    var startDateTime: Date
    
    static func from(_ game: Game) -> ShlWidgetAttributes {
        ShlWidgetAttributes(homeTeam: game.home_team_code, awayTeam: game.away_team_code, gameUuid: game.game_uuid, startDateTime: game.start_date_time)
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
        return data.sorted { (a, b) in a.start_date_time < b.start_date_time }
    }

    func getLiveGames(teamCodes: [String], starred: [String] = []) -> [Game] {
        return getGames()
            .filter({ $0.isLive() })
            .filter(getTeamFilter(teamCodes: teamCodes))
            .sorted { a, b in
                if a.includesTeams(starred) {
                    return true
                }
                return false
            }
    }

    func getPlayedGames(teamCodes: [String]) -> [Game] {
        return getGames()
            .sorted { (a, b) -> Bool in
                return a.start_date_time > b.start_date_time
            }
            .filter({ $0.isPlayed() })
            .filter(getTeamFilter(teamCodes: teamCodes))
    }
    
    func getFutureGames(teamCodes: [String], starred: [String] = []) -> [Game] {
        return Array(data
                        .filter({ $0.isFuture() })
                        .filter(getTeamFilter(teamCodes: teamCodes))
                        .sorted { a, b in
                            if a.start_date_time == b.start_date_time {
                                if a.includesTeams(starred) {
                                    return true
                                }
                            }
                            if a.start_date_time < b.start_date_time {
                                return true
                            }
                            return false
                        }
                        .prefix(5))
    }
    
    func getTeamFilter(teamCodes: [String]) -> (Game) -> Bool {
        if teamCodes.isEmpty {
            return { game in return true }
        }
        
        return { game in teamCodes.contains { game.hasTeam($0) } }
    }
    
    func getGamesBetween(team1: String, team2: String) -> [Game] {
        return getPlayedGames(teamCodes: []).filter { g in
            return g.hasTeam(team1) && g.hasTeam(team2)
        }
    }
    
    func getPoints(for teamCode: String, numberOfGames: Int = 5) -> [Int] {
        return Array(self.data
            .filter { $0.hasTeam(teamCode) }
            .filter { $0.isPlayed() }
            .sorted { $0.start_date_time > $1.start_date_time }
            .map { $0.getPoints(for: teamCode) }
            .prefix(numberOfGames))
        .reversed()
    }
    
    func getPlayoffPoints(for teamCode: String, team2: String, numberOfGames: Int = 5) -> [Int] {
        return Array(getPlayoffGamesBetween(t1: teamCode, t2: team2)
            .sorted { $0.start_date_time > $1.start_date_time }
            .map { !$0.isPlayed() ? -1 : $0.getPoints(for: teamCode) }
            .prefix(numberOfGames))
        .reversed()
    }
    
    func getPlayoffGamesBetween(t1: String, t2: String) -> [Game] {
        self.data
            .filter { $0.isPlayoff() || $0.isDemotion() }
            .filter { $0.includesOnly(teams: [t1, t2])}
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
    
    func includesTeams(_ teams: [String]) -> Bool {
        teams.contains(self.home_team_code) || teams.contains(self.away_team_code)
    }
    
    func includesOnly(teams: [String]) -> Bool {
        teams.contains(self.home_team_code) && teams.contains(self.away_team_code)
    }
    
    func getOpponent(team: String) -> String? {
        guard self.home_team_code == team || self.away_team_code == team else {
            return nil
        }
        return self.home_team_code == team ? self.away_team_code : self.home_team_code
    }
    
    func getPoints(for team: String) -> Int {
        guard isPlayed(),
              (team == home_team_code || team == away_team_code)
        else {
            return 0
        }
        
        if overtime || penalty_shots {
            return didWin(team) ? 2 : 1
        }
        return didWin(team) ? 3 : 0
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
    
   /* func getRank(games: [Game], after gamesPlayed: Int = 1000) -> [Standing] {
        let g = games
            .filter { $0.isPlayed() }
            .filter { $0.hasTeam(team) }
            .sorted { $0.start_date_time > $1.start_date_time }
        data
            .map { self.getRankAfter(games: games, gamesPlayed: gamesPlayed, for: $0.team_code) }
            .sorted {
                if $0.points == $1.points {
                    return $0.diff > $1.diff
                }
                return $0.points > $1.points
            }
            .enumerated()
            .map { Standing(team_code: $0.element.team_code, gp: $0.element.gp, rank: $0.offset + 1, points: $0.element.points, diff: $0.element.diff) }
    }
    
    func getRankAfter(games: [Game], gamesPlayed: Int, for team: String) -> Standing {
        Array(games
            .filter { $0.isPlayed() }
            .filter { $0.hasTeam(team) }
            .sorted { $0.start_date_time > $1.start_date_time }
            .prefix(gamesPlayed))
            .reduce(Standing(team_code: team, gp: 0, rank: 0, points: 0, diff: 0), { s, g in
                var p = g.didWin(team) ? 3 : 0
                if g.penalty_shots || g.overtime {
                    p = g.didWin(team) ? 2 : 1
                }
                let diff = g.home_team_result - g.away_team_result
                return Standing(team_code: s.team_code, gp: s.gp + 1, rank: -1, points: s.points + p, diff: s.diff + diff)
        })
    }*/
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
    @Published var teams = [Team]()
    @Published var teamsMap = [String:Team]()
    
    func getTeam(_ code: String) -> Team? {
        return teamsMap[code]
    }
    
    func getName(_ code: String) -> String {
        return teamsMap[code]?.name ?? code
    }
    
    func getShortname(_ code: String) -> String {
        return teamsMap[code]?.shortname ?? code
    }

    func setTeams(teams: [Team]) {
        self.teams = teams
        for team in teams {
            self.teamsMap[team.code] = team
        }
    }
}

struct Team: Codable, Hashable {
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

struct StartLiveActivity: Codable, Equatable {
    var user_id: String
    var token: String
    var game_uuid: String
}

struct EndLiveActivity: Codable, Equatable {
    var user_id: String
    var game_uuid: String
}

struct PlayoffEntry: Codable, Identifiable, Equatable {
    var id: String {
        return "\(team1)_\(team2)"
    }
    var team1: String
    var team2: String
    var score1: UInt8
    var score2: UInt8
    var eliminated: String?
    var nr_games: Int? = 7
    
    func getNrGames() -> Int {
        nr_games ?? 7
    }
    
    func getBestTo() -> Int {
        Int(ceil(Double(getNrGames()) / 2))
    }
    
    func has(t1: String, t2: String) -> Bool {
        let ts = [t1, t2]
        return ts.contains(team1) && ts.contains(team2)
    }
    
    func has(t1: String) -> Bool {
        team1 == t1 || team2 == t1
    }
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
    
    init(data: Playoffs? = nil) {
        self.data = data
    }
    
    func set(data: Playoffs?) {
        self.data = data
        self.objectWillChange.send()
    }
    
    func getStage(entry: PlayoffEntry) -> String? {
        if self.data?.final == entry {
            return "Final"
        }
        if self.data?.semi?.contains(entry) ?? false {
            return "Semifinal"
        }
        if self.data?.quarter?.contains(entry) ?? false {
            return "Quarterfinal"
        }
        if self.data?.eight?.contains(entry) ?? false {
            return "Eightfinal"
        }
        if self.data?.demotion == entry {
            return "Demotion"
        }
        return nil
    }
    
    func getEntry(team: String) -> PlayoffEntry? {
        func getArr(entry: PlayoffEntry?) -> [PlayoffEntry] {
            entry != nil ? [entry!] : []
        }
        
        var entries = getArr(entry: self.data?.final)
        entries += (self.data?.semi ?? [])
        entries += (self.data?.quarter ?? [])
        entries += (self.data?.eight ?? [])
        entries += getArr(entry: self.data?.demotion)
        
        return entries.first(where: { $0.has(t1: team) })
    }
}
