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

func getPlayedGame(t1: String, s1: Int, t2: String, s2: Int, overtime: Bool = false, date: Date = Date().addingTimeInterval(TimeInterval(-2_000))) -> Game {
    return Game(game_uuid: UUID().uuidString, away_team_code: t2, away_team_result: s2, home_team_code: t1, home_team_result: s1, start_date_time: date, game_type: GameType.season.rawValue, played: true, overtime: overtime, shootout: false, status: "Finished", gametime: "20:00", league: .shl, votes: VotesPerGame(home_perc: 58, away_perc: 42))
}


func getPlayoffGame(t1: String, s1: Int, t2: String, s2: Int, status: String = "Finished") -> Game {
    return Game(game_uuid: UUID().uuidString, away_team_code: t2, away_team_result: s2, home_team_code: t1, home_team_result: s1, start_date_time: Date(), game_type: GameType.playoff.rawValue, played: true, overtime: false, shootout: false, status: status, gametime: "20:00", league: .shl, votes: VotesPerGame(home_perc: 58, away_perc: 42))
}

func getLiveGame() -> Game {
    return getLiveGame(t1: "LHF", score1: 2, t2: "FHC", score2: 0, status: "Period2")
}

func getLiveGame(t1: String, score1: Int, t2: String, score2: Int, status: String? = "Period2") -> Game {
    return Game(game_uuid: UUID().uuidString, away_team_code: t2, away_team_result: score2, home_team_code: t1, home_team_result: score1, start_date_time: Date().addingTimeInterval(TimeInterval(-50)), game_type: GameType.season.rawValue, played: false, overtime: false, shootout: false, status: status, gametime: "13:37", league: .shl, votes: VotesPerGame(home_perc: 58, away_perc: 42))
}

func getFutureGame() -> Game {
    return getFutureGame(t1: "LHF", t2: "FHC")
}

func getFutureGame(t1: String, t2: String) -> Game {
   return getFutureGame(t1: t1, t2: t2, days: 5)
}

func getFutureGame(t1: String, t2: String, days: Int) -> Game {
    let futDate = Calendar.current.date(byAdding: DateComponents(day: days), to: Date()) ?? Date()
    return Game(game_uuid: UUID().uuidString, away_team_code: t2, away_team_result: 0, home_team_code: t1, home_team_result: 0, start_date_time: futDate,
                game_type: GameType.season.rawValue, played: false, overtime: false, shootout: false, status: "Coming", gametime: nil, league: .shl, votes: VotesPerGame(home_perc: 58, away_perc: 42))
}

func getStanding(_ teamCode: String, rank: Int) -> Standing {
    return getStanding(teamCode, rank: rank, gp: 4, points: 15)
}


func getStanding(_ teamCode: String, rank: Int, gp: Int, points: Int) -> Standing {
    return Standing(team_code: teamCode, gp: gp, rank: rank, points: points, diff: 10, league: .shl)
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
    Player(id: id, team_code: "LHF", first_name: "Lars", family_name: "Larsson", jersey: 69, position: "LD", season: "Season2022", gp: 1, toi_s: 1337, g: g, a: a, pim: pim)
}

func getPlayerStats(id: Int, g: Int, a: Int, pim: Int) -> Player {
    Player(id: id, team_code: "LHF", first_name: "Lars", family_name: "Larsson", jersey: 69, position: "LD", season: "Season2022", gp: 1, toi_s: 1337, g: g, a: a, pim: pim)
}

func getEventPlayer() -> EventPlayer {
    return EventPlayer(first_name: "Lars", family_name: "Larsson", jersey: 69)
}

func getEvent(type: GameEventType, period: Int = 1, team: String = "LHF") -> GameEvent {
    switch type {
    case .goal:
        return GameEvent(game_uuid: UUID().uuidString, event_id: "event_id", status: "Period1", gametime: "13:37", type: type.rawValue, team: team, reason: nil, player: getEventPlayer(), penalty: nil, home_team_result: 3, away_team_result: 0, team_advantage: "PP1")
    case .penalty:
        return GameEvent(game_uuid: UUID().uuidString, event_id: "event_id", status: "Period1", gametime: "13:37", type: type.rawValue, team: team, reason: "Too many players on the ice", player: getEventPlayer(), penalty: "2 min + GM", home_team_result: nil, away_team_result: nil, team_advantage: nil)
    default:
        return GameEvent(game_uuid: UUID().uuidString, event_id: "event_id", status: "Period1", gametime: "13:37", type: type.rawValue, team: team, reason: nil, player: nil, penalty: nil, home_team_result: nil, away_team_result: nil, team_advantage: nil)
    }
    
}

func getTeamsData() -> TeamsData {
    let teamsData = TeamsData()
    teamsData.setTeams(teams: [
        Team( code: "TIK", name: "Timrå IK", shortname: "Timrå", display_code: "TIK", league: .shl, golds: nil, founded: nil ),
        Team( code: "VLH", name: "Växjö Lakers", shortname: "Växjö", display_code: "VLH", league: .shl, golds: nil, founded: nil ),
        Team( code: "RBK", name: "Rögle BK", shortname: "Rögle", display_code: "RBK", league: .shl, golds: nil, founded: nil ),
        Team( code: "LIF", name: "Leksands IF", shortname: "Leksand", display_code: "LIF", league: .shl, golds: nil, founded: nil ),
        Team( code: "SAIK", name: "Skellefteå AIK", shortname: "Skellefteå", display_code: "SKE", league: .shl, golds: nil, founded: nil ),
        Team( code: "LHF", name: "Luleå HF", shortname: "Luleå", display_code: "LHF", league: .shl, golds: ["1976", "1977", "1978", "1979", "1986", "1987", "1988", "1989", "1996", "1997", "1998", "1999"], founded: "1976" ),
        Team( code: "OHK", name: "Örebro Hockey", shortname: "Örebro", display_code: "ÖRE", league: .shl, golds: nil, founded: nil ),
        Team( code: "FHC", name: "Frölunda HC", shortname: "Frölunda", display_code: "FHC", league: .shl, golds: nil, founded: nil ),
        Team( code: "FBK", name: "Färjestad BK", shortname: "Färjestad", display_code: "FBK", league: .shl, golds: nil, founded: nil ),
        Team( code: "MIF", name: "IF Malmö Redhawks", shortname: "Malmö", display_code: "MIF", league: .shl, golds: nil, founded: nil ),
        Team( code: "IKO", name: "IK Oskarshamn", shortname: "Oskarshamn", display_code: "IKO", league: .shl, golds: nil, founded: nil ),
        Team( code: "LHC", name: "Linköpings HC", shortname: "Linköping", display_code: "LHC", league: .shl, golds: nil, founded: nil ),
        Team( code: "HV71", name: "HV71", shortname: "HV71", display_code: "HV71", league: .shl, golds: nil, founded: nil),
        
        Team( code: "IFB", name: "IF Björklöven", shortname: "Björklöven", display_code: "IFB", league: .ha, golds: nil, founded: nil),
        Team( code: "DIF", name: "Djurgården IF", shortname: "Djurgården", display_code: "DIF", league: .ha, golds: nil, founded: nil ),
        Team( code: "BIF", name: "Brynäs IF", shortname: "Brynäs", display_code: "BIF", league: .ha, golds: nil, founded: nil ),
    ])
    return teamsData
}

func getPlayoffs() -> PlayoffRsp {
    let playoff = Playoffs(
                demotion: PlayoffEntry(team1: "HV71", team2: "MIF", score1: 2, score2: 2),
                eight: [
                    PlayoffEntry(team1: "LHF", team2: "OHK", score1: 2, score2: 1, eliminated: "OHK"),
                    PlayoffEntry(team1: "RBK", team2: "LIF", score1: 2, score2: 1, eliminated: "LIF"),
                ],
                quarter: [
                    PlayoffEntry(team1: "LHF", team2: "OHK", score1: 2, score2: 1),
                    PlayoffEntry(team1: "TIK", team2: "SAIK", score1: 2, score2: 1, eliminated: "SAIK"),
                    PlayoffEntry(team1: "HV71", team2: "FBK", score1: 2, score2: 1),
                    PlayoffEntry(team1: "FHC", team2: "RBK", score1: 2, score2: 4, eliminated: "FHC")
                ],
                semi: [
                    PlayoffEntry(team1: "LHF", team2: "SAIK", score1: 2, score2: 1),
                    PlayoffEntry(team1: "HV71", team2: "TBD", score1: 0, score2: 0)
                ],
                final: PlayoffEntry(team1: "FHC", team2: "RBK", score1: 2, score2: 1)
            )
    return PlayoffRsp(SHL: playoff, HA: Playoffs())
}


func getGamesData() -> GamesData {
    GamesData(data: [
        getLiveGame(t1: "MIF", score1: 4, t2: "MODO", score2: 2, status: "Intermission"),
        getLiveGame(t1: "MIF", score1: 1, t2: "TIK", score2: 3, status: nil),
        getLiveGame(t1: "LHF", score1: 4, t2: "FHC", score2: 2),
                           
        getPlayedGame(t1: "LHF", s1: 4, t2: "FBK", s2: 1),
        getPlayedGame(t1: "SAIK", s1: 3, t2: "TIK", s2: 1, overtime: true),
        getPlayedGame(t1: "OHK", s1: 2, t2: "MODO", s2: 1, overtime: true, date: Date().addingTimeInterval(TimeInterval(-1000_000))),

        getFutureGame(t1: "LHF", t2: "TBD", days: 1),
        getFutureGame(t1: "LHF", t2: "TIK", days: 2)])
}

func getStandingsData() -> StandingsData {
    StandingsData(data: StandingRsp(SHL: [
        getStanding("LHF", rank: 1),
        getStanding("FBK", rank: 2),
        getStanding("RBK", rank: 3),
        getStanding("IKO", rank: 4),
        getStanding("FHC", rank: 5),
        getStanding("TIK", rank: 6),
        getStanding("MIF", rank: 7),
        getStanding("SAIK", rank: 8),
    ], HA: []))
}

func getPickemData() -> PickemData {
    PickemData(user_id: "123", provider: nil, errorHandler: nil)
}
