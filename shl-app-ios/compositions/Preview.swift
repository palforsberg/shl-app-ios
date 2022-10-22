//
//  Preview.swift
//  shl-app-ios
//
//  Created by Pål on 2021-07-30.
//

import Foundation


func getPlayedGame() -> Game {
    return getPlayedGame(t1: "LHF", s1: 2, t2: "FHC", s2: 0)
}

func getPlayedGame(t1: String, s1: Int, t2: String, s2: Int) -> Game {
    return Game(game_id: 1, game_uuid: UUID().uuidString, away_team_code: t2, away_team_result: s2, home_team_code: t1, home_team_result: s1, start_date_time: Date().addingTimeInterval(TimeInterval(-2_000)), game_type: GameType.season.rawValue, played: true, overtime: false, penalty_shots: false, status: "Finished")
}

func getLiveGame() -> Game {
    return getLiveGame(t1: "LHF", score1: 2, t2: "FHC", score2: 0, status: "Period2")
}

func getLiveGame(t1: String, score1: Int, t2: String, score2: Int, status: String? = "Period2") -> Game {
    return Game(game_id: 1, game_uuid: UUID().uuidString, away_team_code: t2, away_team_result: score2, home_team_code: t1, home_team_result: score1, start_date_time: Date().addingTimeInterval(TimeInterval(-2_000)), game_type: GameType.season.rawValue, played: false, overtime: false, penalty_shots: false, status: status)
}

func getFutureGame() -> Game {
    return getFutureGame(t1: "LHF", t2: "FHC")
}

func getFutureGame(t1: String, t2: String) -> Game {
   return getFutureGame(t1: t1, t2: t2, days: 5)
}

func getFutureGame(t1: String, t2: String, days: Int) -> Game {
    let futDate = Calendar.current.date(byAdding: DateComponents(day: days), to: Date()) ?? Date()
    return Game(game_id: 1, game_uuid: UUID().uuidString, away_team_code: t2, away_team_result: 0, home_team_code: t1, home_team_result: 0, start_date_time: futDate,
                game_type: GameType.season.rawValue, played: false, overtime: false, penalty_shots: false, status: "Coming")
}

func getStanding(_ teamCode: String, rank: Int) -> Standing {
    return getStanding(teamCode, rank: rank, gp: 4, points: 15)
}


func getStanding(_ teamCode: String, rank: Int, gp: Int, points: Int) -> Standing {
    return Standing(team_code: teamCode, gp: gp, rank: rank, points: points, diff: 10)
}

func getPlayers() -> [String: TeamPlayers] {
    let players = TeamPlayers(players: [getPlayer(id: 1, g: 14, a: 2, pim: 0),
                                        getPlayer(id: 2, g: 0, a: 5, pim: 0),
                                        getPlayer(id: 3, g: 2, a: 0, pim: 0),
                                        getPlayer(id: 4, g: 0, a: 2, pim: 12),
                                        getPlayer(id: 5, g: 2, a: 1, pim: 0),
                                       ])
    return [ "LHF": players ]
}
 
func getPlayersWithZeroScore() -> [String: TeamPlayers] {
    return [
        "LHF": TeamPlayers(players: [getPlayer(id: 1, g: 0, a: 0, pim: 0),
                            getPlayer(id: 2, g: 0, a: 0, pim: 0),
                            getPlayer(id: 3, g: 0, a: 0, pim: 0)])
    ]
}

func getPlayer(id: Int, g: Int, a: Int, pim: Int) -> Player {
    return Player(player: id, team: "LHF", firstName: "Lars", familyName: "Larsson", toi: "13:37", jersey: 69, g: g, a: a, pim: pim, position: "LD")
}

func getEventPlayer() -> EventPlayer {
    return EventPlayer(firstName: "Lars", familyName: "Larsson", jersey: 69)
}

func getEvent(type: GameEventType, period: Int = 1, team: String = "LHF") -> GameEvent {
    let info: GameEventInfo
    switch type {
    case .goal:
        info = GameEventInfo(homeTeamId: "LHF", awayTeamId: "FHC", homeResult: 3, awayResult: 0, team: team, player: getEventPlayer(), teamAdvantage: "PP1")
        break
    case .periodStart, .periodEnd:
        info = GameEventInfo(homeTeamId: "LHF", awayTeamId: "FHC", homeResult: 0, awayResult: 0, periodNumber: period)
        break
    case .penalty:
        info = GameEventInfo(homeTeamId: "LHF", awayTeamId: "FHC", homeResult: 0, awayResult: 0, team: team, player: getEventPlayer(), penalty: 2, reason: "Too many players on the ice")
        break
    default:
        info = GameEventInfo(homeTeamId: "LHF", awayTeamId: "FHC", homeResult: 3, awayResult: 0)
        break
    }
    return GameEvent(type: type.rawValue, info: info, timestamp: Date.now, id: type.rawValue + period.formatted(), gametime: "13:37")
}

func getTeamsData() -> TeamsData {
    let teamsData = TeamsData()
    teamsData.setTeams(teams: [
        Team( code: "TIK", name: "Timrå IK", shortname: "Timrå" ),
        Team( code: "VLH", name: "Växjö Lakers", shortname: "Växjö" ),
        Team( code: "RBK", name: "Rögle BK", shortname: "Rögle" ),
        Team( code: "LIF", name: "Leksands IF", shortname: "Leksand" ),
        Team( code: "SAIK", name: "Skellefteå AIK", shortname: "Skellefteå" ),
        Team( code: "LHF", name: "Luleå HF", shortname: "Luleå" ),
        Team( code: "OHK", name: "Örebro Hockey", shortname: "Örebro" ),
        Team( code: "FHC", name: "Frölunda HC", shortname: "Frölunda" ),
        Team( code: "FBK", name: "Färjestad BK", shortname: "Färjestad" ),
        Team( code: "MIF", name: "IF Malmö Redhawks", shortname: "Malmö" ),
        Team( code: "DIF", name: "Djurgården IF", shortname: "Djurgården" ),
        Team( code: "IKO", name: "IK Oskarshamn", shortname: "Oskarshamn" ),
        Team( code: "LHC", name: "Linköpings HC", shortname: "Linköping" ),
        Team( code: "BIF", name: "Brynäs IF", shortname: "Brynäs" ),
        Team( code: "HV71", name: "HV71", shortname: "HV71"),
    ])
    return teamsData
}
