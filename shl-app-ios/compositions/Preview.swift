//
//  Preview.swift
//  shl-app-ios
//
//  Created by Pål on 2021-07-30.
//

import Foundation


func getPlayedGame() -> Game {
    return Game(game_id: 1, game_uuid: "123", away_team_code: "FHC", away_team_result: 0, home_team_code: "LHF", home_team_result: 2, start_date_time: Date().addingTimeInterval(TimeInterval(-2_000)), game_type: GameType.season.rawValue, played: true)
}

func getLiveGame() -> Game {
    return getLiveGame(score1: 2, score2: 0 )
}


func getLiveGame(score1: Int, score2: Int) -> Game {
    return Game(game_id: 1, game_uuid: "123", away_team_code: "FHC", away_team_result: score2, home_team_code: "LHF", home_team_result: score1, start_date_time: Date().addingTimeInterval(TimeInterval(-2_000)), game_type: GameType.season.rawValue, played: false)
}

func getFutureGame() -> Game {
    let futDate = Calendar.current.date(byAdding: DateComponents(day:5), to: Date())
    return Game(game_id: 1, game_uuid: "123", away_team_code: "FHC", away_team_result: 0, home_team_code: "LHF", home_team_result: 2, start_date_time: futDate!,
                game_type: GameType.season.rawValue, played: false)
}

func getStanding(_ teamCode: String, rank: Int) -> Standing {
    return getStanding(teamCode, rank: rank, gp: 4, points: 15)
}


func getStanding(_ teamCode: String, rank: Int, gp: Int, points: Int) -> Standing {
    return Standing(team_code: teamCode, gp: gp, rank: rank, points: points, diff: 10)
}
