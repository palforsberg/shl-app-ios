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
    var homeTeamDisplayCode: String
    var awayTeamDisplayCode: String
    var gameUuid: String
    var startDateTime: Date
    
    static func from(_ game: Game, teamsData: TeamsData) -> ShlWidgetAttributes {
        ShlWidgetAttributes(homeTeam: game.home_team_code,
                            awayTeam: game.away_team_code,
                            homeTeamDisplayCode: teamsData.getDisplayCode(game.home_team_code),
                            awayTeamDisplayCode: teamsData.getDisplayCode(game.away_team_code),
                            gameUuid: game.game_uuid,
                            startDateTime: game.start_date_time)
    }
}

enum GameType: String, Codable {
    case playoff = "PlayOff"
    case season = "Season"
    case kvalmatch = "Demotion"
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
    var data: [Game]
    
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
        let games = data
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
        
        var result: [Game] = []
        for e in games {
            if result.count > 4 {
                let sameDay = Calendar.current.isDate(e.start_date_time, equalTo: result.last?.start_date_time ?? Date.distantPast, toGranularity: .day)
                if sameDay {
                    result.append(e)
                } else {
                    break
                }
            } else {
                result.append(e)
            }
        }
        return result
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


    func getStandingTimeline(league: League) -> StandingTimeline {
        var team_series: [String: [Standing]] = [:]
        var team_sums: [String: Standing] = [:]
        var max_gp = 0
        
        func update(code: String, p: Int, d: Int) {
            var sum = team_sums[code] ?? Standing(team_code: code, gp: 0, rank: -1, points: 0, diff: 0, league: league)
            sum.points += p
            sum.diff += d
            sum.gp += 1
            team_sums[code] = sum
             
            var series = team_series[code] ?? [Standing(team_code: code, gp: 0, rank: -1, points: 0, diff: 0, league: league)]
            series.append(sum)
            team_series[code] = series
            
            max_gp = max(max_gp, sum.gp)
        }
        
        func getLast(_ entries: [Standing], index: Int, code: String) -> Standing {
            entries[safe: index] ?? entries.last ?? Standing(team_code: code, gp: 0, rank: -1, points: 0, diff: 0, league: .shl)
        }
         
        self.data
            .filter { $0.isPlayed() }
            .filter { $0.getGameType() == GameType.season }
            .filter { $0.league == league }
            .sorted { $0.start_date_time > $1.start_date_time }
            .forEach { game in
                update(code: game.home_team_code, p: game.getPoints(for: game.home_team_code), d: game.getDiff(for: game.home_team_code))
                update(code: game.away_team_code, p: game.getPoints(for: game.away_team_code), d: game.getDiff(for: game.away_team_code))
        }
        
        
        var result: [Int: [Standing]] = [:]
        for i in 0...max_gp {
            let entries = team_series.map({e in getLast(e.value, index: i, code: e.key) })
            let standing = entries.sorted(by: {(a, b) in
                if a.points == b.points {
                    return a.diff > b.diff
                } else {
                    return a.points > b.points
                }
            })
                .enumerated()
                .map { Standing(team_code: $1.team_code, gp: $1.gp, rank: $0 + 1, points: $1.points, diff: $1.diff, league: $1.league) }
            
            result[i] = standing
        }
        
        return StandingTimeline(gp: max_gp, timeline: result)
     }
}

struct StandingTimeline {
    let gp: Int
    let timeline: [Int: [Standing]]
    
    func getCurrent() -> [Standing] {
        timeline[gp - 1] ?? []
    }
}

struct VotesPerGame: Codable, Equatable {
    let home_perc: Int
    let away_perc: Int
}

struct Game: Codable, Identifiable, Equatable  {
    var id: String {
        return game_uuid
    }
    let game_uuid: String
    let away_team_code: String
    let away_team_result: Int
    let home_team_code: String
    let home_team_result: Int
    let start_date_time: Date
    let game_type: String
    let played: Bool
    let overtime: Bool
    let shootout: Bool
    let status: String?
    let gametime: String?
    let league: League
    var votes: VotesPerGame?
    
    func hasTeam(_ teamCode: String) -> Bool {
        return away_team_code == teamCode || home_team_code == teamCode
    }
    
    func isHome(_ teamCode: String) -> Bool {
        return teamCode == home_team_code
    }
    
    func homeWon() -> Bool {
        return played && home_team_result > away_team_result
    }
    
    func isTbd() -> Bool {
        home_team_code == "TBD" || away_team_code == "TBD"
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
    
    func getWinner() -> String {
        guard isPlayed() else {
            return ""
        }
        return didWin(home_team_code) ? home_team_code : away_team_code
    }

    func isPlayoff() -> Bool {
        self.game_type == "PlayOff"
    }
    
    func isDemotion() -> Bool {
        self.game_type == "Demotion"
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
        
        if overtime || shootout {
            return didWin(team) ? 2 : 1
        }
        return didWin(team) ? 3 : 0
    }
    
    func getDiff(for team: String) -> Int {
        guard isPlayed(),
              (team == home_team_code || team == away_team_code)
        else {
            return 0
        }
        if team == home_team_code {
            return home_team_result - away_team_result
        } else {
            return away_team_result - home_team_result
        }
    }
}


class StandingsData: ObservableObject {
    public var data: StandingRsp
    
    init(data: StandingRsp) {
        self.data = data
    }
    
    func get(for league: League) -> [Standing] {
        switch league {
            case .shl: return data.SHL
            case .ha: return data.HA
        }
    }

    func set(data: StandingRsp) {
        self.data = data
        self.objectWillChange.send()
    }
    
    func getFor(team: String) -> Standing? {
        return self.data.getAll().first(where: { $0.team_code == team })
    }
}

enum League : String, Codable {
    case shl = "SHL"
    case ha = "HA"
}

struct StandingRsp: Codable {
    var SHL: [Standing]
    var HA: [Standing]
    
    func getAll() -> [Standing] {
        SHL + HA
    }
}

struct Standing: Codable, Identifiable {
    var id: String {
        return team_code
    }
    let team_code: String
    var gp: Int
    let rank: Int
    var points: Int
    var diff: Int
    var league: League
    
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
    
    init(teams: [Team] = [Team]()) {
        self.setTeams(teams: teams)
    }
    
    func getTeam(_ code: String) -> Team? {
        return teamsMap[code]
    }
    
    func getTeams(_ league: League) -> [Team] {
        return teams.filter { $0.league == league }
    }
    
    func getName(_ code: String) -> String {
        return teamsMap[code]?.name ?? code
    }
    
    func getShortname(_ code: String) -> String {
        return teamsMap[code]?.shortname ?? code
    }
    
    func getDisplayCode(_ code: String) -> String {
        return teamsMap[code]?.display_code ?? code
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
    let display_code: String
    let league: League?
    let golds: [String]?
    let founded: String?
}

struct GameDetails: Codable {
    var game: Game
    var events: [GameEvent]
    let stats: ApiGameStats?
    let players: [Player]
}

struct ApiGameStats: Codable {
    let home: ApiGameTeamStats
    let away: ApiGameTeamStats
}

struct ApiGameTeamStats: Codable {
    let g: Int
    let sog: Int
    let pim: Int
    let fow: Int
}

struct TeamPlayers: Codable {
    var players: [Player]?
}

struct Player: Codable, Identifiable {
    let id: Int
    var team_code: String
    var first_name: String
    var family_name: String
    var jersey: Int
    var position: String
    var season: String
    
    let gp: Int
    
    // Player stats
    var toi_s: Int?
    var g: Int?
    var a: Int?
    var pim: Int?
    var sog: Int?
    var pop: Int?
    var nep: Int?
    
    // GK stats
    var svs: Int?
    var ga: Int?
    var soga: Int?
    
    func hasPlayed() -> Bool {
        self.gp > 0
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
        return svs ?? 0
    }
    
    func getSavesPercentage() -> Float {
        return ((Float)(svs ?? 0) / (Float)(soga ?? 1)) * 100
    }
    
    func getGoalsPerShotPercentage() -> Float {
        return (Float(g ?? 0) / Float(max(sog ?? 1, 1))) * 100
    }
    
    func getPointsPerGame() -> Float {
        Float(getPoints()) / Float(gp != 0 ? gp : 1)
    }
    
    func getToiFormatted() -> String {
        Player.formatSeconds(toi_s ?? 0)
    }
    
    func getToiPerGame() -> Int {
        (toi_s ?? 0) / (gp != 0 ? gp : 1)
    }
    
    func getToiPerGameFormatted() -> String {
        Player.formatSeconds(getToiPerGame())
    }
    
    static func formatSeconds(_ seconds: Int) -> String {
        let (h, m, s) = (seconds / 3600, (seconds % 3600) / 60, (seconds % 3600) % 60)
        if h > 0 {
            return String(format: "%02d:%02d:%02d", h, m, s)
        }
        return String(format: "%02d:%02d", m, s)
    }
}


struct PlusMinus: Codable {
    var d: Int
}

struct EventPlayer: Codable {
    var first_name: String
    var family_name: String
    var jersey: Int
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
    var id: String {
        "\(game_uuid):\(event_id)"
    }
    let game_uuid: String
    let event_id: String
    let status: String
    let gametime: String
    var type: String
    
    let team: String?
    
    let reason: String?
    let player: EventPlayer?
    let penalty: String?
    
    let home_team_result: Int?
    let away_team_result: Int?
    let team_advantage: String?
    
    func getEventType() -> GameEventType? {
        return GameEventType(rawValue: type)
    }
    func getTeamAdvantage() -> String {
        if self.team_advantage == "EQ" {
            return ""
        }
        return self.team_advantage ?? ""
    }
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


struct PlayoffRsp: Codable {
    var SHL: Playoffs?
    var HA: Playoffs?
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
    
    func getStage(entry: PlayoffEntry) -> String? {
        if self.final == entry {
            return "Final"
        }
        if self.semi?.contains(entry) ?? false {
            return "Semifinal"
        }
        if self.quarter?.contains(entry) ?? false {
            return "Quarterfinal"
        }
        if self.eight?.contains(entry) ?? false {
            return "Eightfinal"
        }
        if self.demotion == entry {
            return "Demotion"
        }
        return nil
    }
    
    func getEntry(team: String) -> PlayoffEntry? {
        func getArr(entry: PlayoffEntry?) -> [PlayoffEntry] {
            entry != nil ? [entry!] : []
        }
        
        var entries = getArr(entry: self.final)
        entries += (self.semi ?? [])
        entries += (self.quarter ?? [])
        entries += (self.eight ?? [])
        entries += getArr(entry: self.demotion)
        
        return entries.first(where: { $0.has(t1: team) })
    }
}

class PlayoffData: ObservableObject {
    var data: PlayoffRsp?
    
    init(data: PlayoffRsp? = nil) {
        self.data = data
    }
    
    func set(data: PlayoffRsp?) {
        self.data = data
        self.objectWillChange.send()
    }
    
    func get(for league: League) -> Playoffs? {
        switch league {
        case .shl: return data?.SHL
        case .ha: return data?.HA
        }
    }
    
    func getStage(entry: PlayoffEntry) -> String? {
        data?.SHL?.getStage(entry: entry) ?? data?.HA?.getStage(entry: entry)
    }
    
    func getEntry(team: String) -> PlayoffEntry? {
        data?.SHL?.getEntry(team: team) ?? data?.HA?.getEntry(team: team)
    }
}


struct PickReq: Codable, Equatable {
    let game_uuid: String
    let user_id: String
    let team_code: String
}


struct Status: Codable {
    let msg: String
    let lvl: String
}


struct StatusRsp: Codable {
    let status: Status?
}
