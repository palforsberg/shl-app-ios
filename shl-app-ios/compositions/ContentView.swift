//
//  ContentView.swift
//  HockeyPal
//
//  Created by Pål Forsberg on 2021-01-08.
//

import SwiftUI


struct GoalAlert: View {
    
    @Binding var alert: String?
    
    var body: some View {
        if alert != nil {
            VStack {
                ZStack {
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color(UIColor.systemYellow))
                        .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 0)
                        .shadow(color: Color.black.opacity(0.2), radius: 10, x: 0, y: 3)
                    Text("🚨 \(alert!) 🚨")
                        .font(.system(size: 18, design: .rounded))
                        .fontWeight(.bold)
                        .foregroundColor(.black)
                }.frame(width: .infinity, height: 70, alignment: .top)
                    .padding(EdgeInsets(top: 0, leading: 30, bottom: 0, trailing: 30))
                    .transition(.scale)
                    .gesture(TapGesture().onEnded { _ in
                        withAnimation {
                            self.alert = nil
                        }
                    })
                    Spacer()
            }
            .transition(AnyTransition.move(edge: .top).combined(with: .opacity))
            .zIndex(1)
        }
    }
}
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
    
    @State
    var alert: String? = nil

    var body: some View {
        ZStack {
            TabView {
                SeasonView(provider: provider).tabItem { Label("Home", systemImage: "house.circle") }
                StandingsView(provider: provider).tabItem { Label("Standings", systemImage: "list.bullet.circle") }
            }
            GoalAlert(alert: $alert)
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
        .onReceive(NotificationCenter.default.publisher(for: .onGameNotification)) { data in
            withAnimation {
                self.alert = (data.object as? GameNofitication)?.title
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 10) {
                withAnimation {
                    self.alert = nil
                }
            }
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
            ]), provider: nil, alert: "MÅÅÅL för Skellefteå")
            .environment(\.locale, .init(identifier: "sv"))
    }
}
