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
    @ObservedObject var standings = StandingsData(data: StandingRsp(SHL: [], HA: []))
    @ObservedObject var settings = AppDelegate.settings
    @ObservedObject var playoffs = PlayoffData()
    
    var provider: DataProvider? = DataProvider()
    
    @State
    var userService: UserService?
    
    @State
    var alert: GameNofitication? = nil
    
    init() {
        if let games = provider?.getCachedGames(season: settings.season) {
            self.gameData.set(data: games)
        }
        if let standing = provider?.getCachedStandings(season: settings.season) {
            self.standings.set(data: standing)
        }
        if let playoffs = provider?.getCachedPlayoffs(season: settings.season) {
            self.playoffs.set(data: playoffs)
        }
        if let teams = provider?.getCachedTeams() {
            self.teams.setTeams(teams: teams)
        }
        
        debugPrint("[ContentView] Init")
    }

    var body: some View {
        ZStack {
            TabView {
                SeasonView(provider: provider).tabItem { Label("Home", systemImage: "hockey.puck.circle").environment(\.symbolVariants, .none) }
                StandingsView(provider: provider).tabItem { Label("Standings", systemImage: "trophy.circle").environment(\.symbolVariants, .none) }
            }
            VStack {
                GameAlert(alert: alert)
                Spacer()
            }
        }.task {
            if let ts = await provider?.getTeams() {
                teams.setTeams(teams: ts)
            }
            userService = UserService(provider: provider, settings: settings, starredTeams: starredTeams)
            Purchases.shared = Purchases(settings: settings)
            LiveActivity.shared = LiveActivity(provider: self.provider!, settings: self.settings)
        }
        .navigationViewStyle(.stack) // To fix Views being popped when updating @EnvironmentObject
        .environmentObject(starredTeams)
        .environmentObject(standings)
        .environmentObject(teams)
        .environmentObject(gameData)
        .environmentObject(settings)
        .environmentObject(playoffs)
        .onReceive(NotificationCenter.default.publisher(for: .onGameNotification)) { data in
            // self.alert = data.object as? GameNofitication
        }
        .background(Color(UIColor.systemGroupedBackground))
        .accentColor(colorScheme == .light
                        ? Color.init(.displayP3, white: 0.1, opacity: 1)
                        : Color.init(.displayP3, white: 0.9, opacity: 1))
    }
}


struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        let teams = getTeamsData()
        
        let starredTeams = StarredTeams()
        starredTeams.addTeam(teamCode: "FHC")
        starredTeams.addTeam(teamCode: "TIK")
        
        var contentView = ContentView()
        contentView.teams = teams
        contentView.gameData = GamesData(data: [
            getLiveGame(t1: "MIF", score1: 1, t2: "TIK", score2: 1, status: "Period3"),
            getLiveGame(t1: "FBK", score1: 4, t2: "FHC", score2: 2),

            getFutureGame(t1: "RBK", t2: "TIK"),
            getFutureGame(t1: "TIK", t2: "VLH"),
            getFutureGame(t1: "BIF", t2: "LHF"),

            getPlayedGame(t1: "LHF", s1: 4, t2: "FBK", s2: 1),
            getPlayedGame(t1: "LIF", s1: 3, t2: "TIK", s2: 1),
        ])
        contentView.standings = getStandingsData()
        contentView.alert = GameNofitication(team: "LHF", game_uuid: "game_uuid_123", title: "MÅÅÅL för Skellefteå!", body: "SAIK 1 - 0 HV71", type: "Goal")
        return contentView
            .environment(\.locale, .init(identifier: "sv"))
    }
}
