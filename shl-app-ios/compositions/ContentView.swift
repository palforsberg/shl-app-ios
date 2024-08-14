//
//  ContentView.swift
//  HockeyPal
//
//  Created by Pål Forsberg on 2021-01-08.
//

import SwiftUI

struct ErrorView: View {
    @EnvironmentObject var errorHandler: ErrorHandler
    
    @State var errorMsg: String?
    @State var workItem: DispatchWorkItem?
    
    var body: some View {
        VStack {
            if let e = self.errorMsg {
                HStack {
                    Image(systemName: "exclamationmark.octagon")
                        .foregroundColor(Color(UIColor.systemRed))
                    Text(LocalizedStringKey(e))
                }
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .padding()
                .background(.ultraThinMaterial)
                .cornerRadius(20)
                .onTapGesture {
                    self.workItem?.perform()
                }
                .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        
        .onReceive(errorHandler.$error) { error in
            withAnimation(.spring()) {
                self.errorMsg = error
            }
            
            if let e = error {
                self.workItem?.cancel()
                self.workItem = DispatchWorkItem {
                    print("[ErrorView] Workitem")
                    self.errorHandler.set(error: nil)
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 6, execute: self.workItem!)
                print("[ErrorView] \(e)")
            }
        }
    }
}

struct ContentView: View {
    
    @Environment(\.colorScheme) var colorScheme
    
    @ObservedObject var starredTeams = StarredTeams()
    @ObservedObject var teams = TeamsData()
    @ObservedObject var gameData = GamesData(data: [])
    @ObservedObject var standings = StandingsData(data: StandingRsp(SHL: [], HA: []))
    @ObservedObject var settings = AppDelegate.settings
    @ObservedObject var playoffs = PlayoffData()
    @ObservedObject var pickemData: PickemData
    @ObservedObject var errorHandler = ErrorHandler()
    @ObservedObject var playersData = PlayersData(data: [])
    
    var provider: DataProvider? = DataProvider()
    
    @State
    var userService: UserService?
    
    @State
    var alert: GameNofitication? = nil
    
    init() {
        self.pickemData = PickemData(user_id: AppDelegate.settings.uuid,
                                     provider: self.provider, errorHandler: nil)
        
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
        if let players = provider?.getCachedPlayers(for: settings.season) {
            self.playersData.set(data: players)
        }
        
        self.pickemData.errorHandler = errorHandler
        debugPrint("[ContentView] Init")
    }

    var body: some View {
        ZStack {
            TabView {
                SeasonView(provider: provider)
                    .tabItem { Label("Home", systemImage: getImageForGamesView())
                        .environment(\.symbolVariants, .none) }
                StandingsView(provider: provider)
                    .tabItem { Label("Standings", systemImage: getImageForStandingsView())
                        .environment(\.symbolVariants, .none) }
                PlayerView(provider: provider)
                    .tabItem {
                        Image("figure.hockey.circle").renderingMode(.template)
                        Text("Players")
                    }
            }
            VStack {
                GameAlert(alert: alert)
                Spacer()
            }
            VStack {
                ErrorView()
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
        .environmentObject(pickemData)
        .environmentObject(errorHandler)
        .environmentObject(playersData)
        .onReceive(NotificationCenter.default.publisher(for: .onGameNotification)) { data in
            // self.alert = data.object as? GameNofitication
        }
        .background(Color(UIColor.systemGroupedBackground))
        .accentColor(colorScheme == .light
                        ? Color.init(.displayP3, white: 0.1, opacity: 1)
                        : Color.init(.displayP3, white: 0.9, opacity: 1))
    }
    
    func getImageForGamesView() -> String {
        return "hockey.puck.circle"
    }
    
    func getImageForStandingsView() -> String {
        return "trophy.circle"
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
