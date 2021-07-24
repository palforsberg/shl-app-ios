//
//  ContentView.swift
//  HockeyPal
//
//  Created by Pål Forsberg on 2021-01-08.
//

import SwiftUI

struct ContentView: View {
    
    @ObservedObject var starredTeams = StarredTeams()
    @ObservedObject var teams = Teams()
    
    var body: some View {
        TabView {
            GamesView()
                .environmentObject(starredTeams)
                .environmentObject(teams)
                .tabItem { TabItem(text: "Games", image: "house") }
            StandingsView()
                .environmentObject(starredTeams)
                .environmentObject(teams)
                .tabItem { TabItem(text: "Standings", image: "list.number") }
            
        }.onAppear(perform: {
            teams.fetch()
        })
    }
    
}


struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            ContentView()
        }
    }
}
