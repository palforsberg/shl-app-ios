//
//  ContentView.swift
//  HockeyPal
//
//  Created by Pål Forsberg on 2021-01-08.
//

import SwiftUI


struct GoalAlert: View {
    
    @Binding var alert: GameNofitication?
    
    var body: some View {
        if alert != nil && alert?.title != nil {
            VStack {
                ZStack {
                    Rectangle()
                        .fill(Color(UIColor.systemYellow))
                    HStack(spacing: 20) {
                        Text("🚨 MÅL!")
                            .font(.system(size: 40, weight: .black, design: .rounded))
                            .foregroundColor(.black)
                        TeamLogo(code: alert?.team ?? "", size: 110)
                            .frame(height: 90)
                            .clipped()
                    }
                }.frame(width: .infinity, height: 90, alignment: .top)
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

struct TitleAlert: View {
    
    @Binding var alert: GameNofitication?
    
    var body: some View {
        if let a = alert {
            VStack {
                ZStack {
                    RoundedRectangle(cornerRadius: 0)
                        .fill(Color(UIColor.systemYellow))
                    VStack {
                        Text("\(a.title ?? "")")
                            .font(.system(size: 18, weight: .black, design: .rounded))
                            .foregroundColor(.black)
                        Text("\(a.body ?? "")")
                            .font(.system(size: 16, weight: .heavy, design: .rounded))
                            .foregroundColor(.black)
                    }
                }.frame(width: .infinity, height: 80, alignment: .top)
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

struct GameAlert: View {
    @Binding var alert: GameNofitication?
    var body: some View {
        switch alert?.type {
        case "Goal": return AnyView(GoalAlert(alert: $alert))
        default: return AnyView(TitleAlert(alert: $alert))
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
    var alert: GameNofitication? = nil

    var body: some View {
        ZStack {
            TabView {
                SeasonView(provider: provider).tabItem { Label("Home", systemImage: "house.circle") }
                StandingsView(provider: provider).tabItem { Label("Standings", systemImage: "list.bullet.circle") }
            }
            GameAlert(alert: $alert)
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
                self.alert = data.object as? GameNofitication
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
            ]), provider: nil, alert: GameNofitication(team: "LHF", game_uuid: "game_uuid_123", title: "MÅÅÅL för Skellefteå!", body: "SAIK 1 - 0 HV71", type: "Goal"))
            .environment(\.locale, .init(identifier: "sv"))
    }
}
