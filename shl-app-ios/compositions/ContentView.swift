//
//  ContentView.swift
//  HockeyPal
//
//  Created by Pål Forsberg on 2021-01-08.
//

import SwiftUI

struct ContentView: View {
    
    @Environment(\.colorScheme) var colorScheme
    
    @ObservedObject var starredTeams = StarredTeams()
    @ObservedObject var teams = TeamsData()
    @ObservedObject var gameData = GamesData(data: [])
    @ObservedObject var standings = StandingsData(data: [])
    @ObservedObject var settings = AppDelegate.settings
    
    var provider: DataProvider? = DataProvider()
    
    @State
    var userService: UserService?

    var body: some View {
        TabView {
            GamesView(provider: provider).tabItem { Label("Home", systemImage: "house.circle") }
            StandingsView(provider: provider).tabItem { Label("Standings", systemImage: "list.bullet.circle") }
        }.task {
            if let ts = await provider?.getTeams() {
                teams.setTeams(teams: ts)
            }
            userService = UserService(provider: provider, settings: settings, starredTeams: starredTeams)
            Purchases.shared = Purchases(settings: settings)
        }
        .environmentObject(starredTeams)
        .environmentObject(standings)
        .environmentObject(teams)
        .environmentObject(gameData)
        .environmentObject(settings)
        .background(Color(UIColor.systemGroupedBackground))
        .accentColor(colorScheme == .light
                        ? Color.init(.displayP3, white: 0.1, opacity: 1)
                        : Color.init(.displayP3, white: 0.9, opacity: 1))
    }
}


struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        let teams = TeamsData()
        teams.setTeams(teams: [Team(code: "LHF", name: "Luleå HF"),
                               Team(code: "FHC", name: "Frölunda HC"),
                               Team(code: "SAIK", name: "Skellefteå AIK")])
        
        let starredTeams = StarredTeams()
        starredTeams.addTeam(teamCode: "LHF")
        starredTeams.addTeam(teamCode: "TIK")
        return ContentView(
            teams: teams,
            gameData: GamesData(data: [
                getLiveGame(t1: "MIF", score1: 1, t2: "TIK", score2: 1),
                getLiveGame(t1: "LHF", score1: 4, t2: "FHC", score2: 2),

                getFutureGame(t1: "LHF", t2: "TIK"),
                getFutureGame(t1: "TIK", t2: "DIF"),
                getFutureGame(t1: "BIF", t2: "LHF"),

                getPlayedGame(t1: "LHF", s1: 4, t2: "FBK", s2: 1),
                getPlayedGame(t1: "LIF", s1: 3, t2: "TIK", s2: 1),
            ]),
            standings: StandingsData(data: [
                getStanding("LHF", rank: 1),
                getStanding("FBK", rank: 2),
                getStanding("RBK", rank: 3),
                getStanding("IKO", rank: 4),
                getStanding("FHC", rank: 5),
                getStanding("TIK", rank: 6),
                getStanding("MIF", rank: 7),
                getStanding("SAIK", rank: 8),
            ]), provider: nil)
            .environment(\.locale, .init(identifier: "sv"))
    }
}
