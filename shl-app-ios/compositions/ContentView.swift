//
//  ContentView.swift
//  HockeyPal
//
//  Created by Pål Forsberg on 2021-01-08.
//

import SwiftUI

struct ContentView: View {
    
    @ObservedObject var starredTeams = StarredTeams()
    @ObservedObject var teams = TeamsData()
    @ObservedObject var gameData = GamesData(data: [])
    
    var provider: DataProvider? = DataProvider()
    
    var body: some View {
        TabView {
            GamesView().tabItem { () in Label("Home", systemImage: "house") }
            StandingsView().tabItem { Label("Standings", systemImage: "list.bullet") }
        }.onAppear(perform: {
            provider?.getTeams(completion: { ts in
                teams.setTeams(teams: ts)
            })
            provider?.getGames { gd in
                gameData.data = gd
            }
        })
        .environmentObject(starredTeams)
        .environmentObject(teams)
        .environmentObject(gameData)
        .background(Color(UIColor.systemGroupedBackground))
        .accentColor(Color.orange)
    }
    
}


struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            ContentView(starredTeams: StarredTeams(),
                        teams: TeamsData(),
                        gameData: GamesData(data: [getLiveGame(), getLiveGame(),
                                                   getPlayedGame(), getPlayedGame(),
                                                   getFutureGame(), getFutureGame()]),
                        provider: nil)
                .environment(\.locale, .init(identifier: "sv"))
            
        }
    }
}
