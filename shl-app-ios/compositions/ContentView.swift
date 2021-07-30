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
    @StateObject var gameData = GamesData(data: [])
    
    var provider: DataProvider? = DataProvider()
    
    var body: some View {
        TabView {
            GamesView()
                .environmentObject(starredTeams)
                .environmentObject(teams)
                .environmentObject(gameData)
                .tabItem { TabItem(text: "Games", image: "house") }
            StandingsView()
                .environmentObject(starredTeams)
                .environmentObject(teams)
                .environmentObject(gameData)
                .tabItem { TabItem(text: "Standings", image: "list.number") }
        }.onAppear(perform: {
            provider?.getTeams(completion: { ts in
                teams.setTeams(teams: ts)
            })
            provider?.getGames { gd in
                DispatchQueue.main.async {
                    gameData.data = gd
                }
            }
        })
        .environmentObject(starredTeams)
        .environmentObject(teams)
        .environmentObject(gameData)
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
        }
    }
}
