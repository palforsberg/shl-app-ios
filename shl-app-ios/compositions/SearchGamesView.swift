//
//  SearchGamesView.swift
//  shl-app-ios
//
//  Created by Pål on 2023-05-19.
//

import SwiftUI


struct MyMenuStyle: MenuStyle {
    func makeBody(configuration: Configuration) -> some View {
        Menu(configuration)
    }
    
}

struct SearchGamesView: View {
    @Namespace var animation
    
    @EnvironmentObject var starredTeams: StarredTeams
    @EnvironmentObject var gamesData: GamesData
    @EnvironmentObject var settings: Settings
    @EnvironmentObject var teams: TeamsData
    
    @State var selectedTeams: [String] = []
    
    @State var showTeamSelectView = false
    @State var showPlayed = true
    @State var showFuture = false
    
    var body: some View {
        let games = gamesData
                .getGames()
                .filter { g in
                    if self.selectedTeams.isEmpty { return true }
                    return g.includesTeams(self.selectedTeams)
                }
                .filter { g in
                    if showPlayed && g.isPlayed() { return true }
                    if !showPlayed && g.isFuture() { return true }
                    return false
                }
                .sorted { (a, b) -> Bool in
                    if showPlayed {
                        return a.start_date_time > b.start_date_time
                    } else {
                        return a.start_date_time < b.start_date_time
                    }
                }
        List {
            Group {
                Button {
                    self.showTeamSelectView.toggle()
                } label: {
                    HStack(spacing: 2) {
                        if selectedTeams.isEmpty {
                            ForEach(teams.teams, id: \.code) { g in
                                TeamLogo(code: g.code, size: 40)
                                    .opacity(0.4)
                            }
                        } else {
                            ForEach(selectedTeams, id: \.self) { g in
                                TeamLogo(code: g, size: 40)
                            }
                        }
                    }
                    .padding(.bottom, 2)
                    .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 2)
                }

                HStack {
                    Picker("GameStatus", selection: $showPlayed) {
                        Text("Coming")
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .tag(false)
                        Text("Played")
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .tag(true)
                    }
                    .pickerStyle(.segmented)
                    /*Button("Coming") {
                        withAnimation {
                            showFuture.toggle()
                            showPlayed.toggle()
                        }
                    }
                    .padding(EdgeInsets(top: 8, leading: 10, bottom: 8, trailing: 10))
                    .foregroundColor(Color(uiColor: .label))
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .cornerRadius(10)
                    .opacity(showFuture ? 1 : 0.4)
                    .buttonStyle(PlainButtonStyle())
                    
                    Button("Played") {
                        withAnimation {
                            showFuture.toggle()
                            showPlayed.toggle()
                        }
                    }
                    .padding(EdgeInsets(top: 8, leading: 10, bottom: 8, trailing: 10))
                    .foregroundColor(Color(uiColor: .label))
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .cornerRadius(10)
                    .opacity(showPlayed ? 1 : 0.4)
                    .buttonStyle(PlainButtonStyle())*/
                }
                .padding(.bottom, 0)
            }
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)
            Section(header: Text("Result").listHeader()) {
                ForEach(games) { (item) in
                    NavigationLink {
                        GamesStatsView(game: item)
                    } label: {
                        if item.isLive() {
                            LiveGame(game: item)
                                .padding(EdgeInsets(top: 10, leading: -10, bottom: 10, trailing: -10))
                        } else if item.isFuture() {
                            ComingGame(game: item)
                                .padding(EdgeInsets(top: 10, leading: -10, bottom: 10, trailing: -10))
                        } else {
                            PlayedGame(game: item)
                                .padding(EdgeInsets(top: 10, leading: -10, bottom: 10, trailing: -10))
                        }
                    }
                }
            }
        }
        .navigationBarTitle(Text("Search"))
        .onAppear {
            selectedTeams = settings.onlyStarred ? starredTeams.starredTeams : []
        }
        .sheet(isPresented: $showTeamSelectView) {
            if #available(iOS 16.0, *) {
                TeamSelectView(selectedTeams: $selectedTeams)
                    .presentationDragIndicator(.visible)
                    .presentationDetents([.medium])
            } else {
                TeamSelectView(selectedTeams: $selectedTeams)
            }
        }
    }
}

struct SearchGamesView_Previews: PreviewProvider {
    static var previews: some View {
        let gamesData = GamesData(data: [
                                    getLiveGame(t1: "MIF", score1: 4, t2: "TIK", score2: 2, status: "Intermission"),
                                    getLiveGame(t1: "MIF", score1: 1, t2: "TIK", score2: 3, status: nil),
                                    getLiveGame(t1: "LHF", score1: 4, t2: "FHC", score2: 2),
                                                       
                                    getPlayedGame(t1: "LHF", s1: 4, t2: "FBK", s2: 1),
                                    getPlayedGame(t1: "SAIK", s1: 3, t2: "TIK", s2: 1, overtime: true),
                                    getPlayedGame(t1: "OHK", s1: 2, t2: "RBK", s2: 1, overtime: true, date: Date().addingTimeInterval(TimeInterval(-1000_000))),
                
                                    getFutureGame(t1: "LHF", t2: "TBD", days: 1),
                                    getFutureGame(t1: "LHF", t2: "TIK", days: 2)])
        let starredTeams = StarredTeams()
        starredTeams.addTeam(teamCode: "LHF")
        starredTeams.addTeam(teamCode: "TIK")
        starredTeams.addTeam(teamCode: "RBK")
        
        return SearchGamesView()
            .environmentObject(gamesData)
            .environmentObject(Settings())
            .environmentObject(starredTeams)
            .environmentObject(getTeamsData())
    }
}
