//
//  ContentView.swift
//  HockeyPal
//
//  Created by Pål Forsberg on 2021-01-08.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            GamesView().tabItem { TabItem(text: "Home", image: "house") }
            StandingsView().tabItem { TabItem(text: "Standings", image: "list.number") }
        }
    }
}


struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            ContentView()
        }
    }
}
