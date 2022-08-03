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
    return Game(game_id: "1", game_uuid: UUID().uuidString, away_team_code: t2, away_team_result: s2, home_team_code: t1, home_team_result: s1, start_date_time: Date().addingTimeInterval(TimeInterval(-2_000)), game_type: GameType.season.rawValue, played: true, overtime: false, penalty_shots: false)
}

func getLiveGame() -> Game {
    return getLiveGame(t1: "LHF", score1: 2, t2: "FHC", score2: 0 )
}

func getLiveGame(t1: String, score1: Int, t2: String, score2: Int) -> Game {
    return Game(game_id: "1", game_uuid: UUID().uuidString, away_team_code: t2, away_team_result: score2, home_team_code: t1, home_team_result: score1, start_date_time: Date().addingTimeInterval(TimeInterval(-2_000)), game_type: GameType.season.rawValue, played: false, overtime: false, penalty_shots: false)
}

func getFutureGame() -> Game {
    return getFutureGame(t1: "LHF", t2: "FHC")
}

func getFutureGame(t1: String, t2: String) -> Game {
    let futDate = Calendar.current.date(byAdding: DateComponents(day:5), to: Date()) ?? Date()
    return Game(game_id: "1", game_uuid: UUID().uuidString, away_team_code: t2, away_team_result: 0, home_team_code: t1, home_team_result: 0, start_date_time: futDate,
                game_type: GameType.season.rawValue, played: false, overtime: false, penalty_shots: false)
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
