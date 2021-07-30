//
//  TeamView.swift
//  HockeyPal
//
//  Created by Pål Forsberg on 2021-01-14.
//

import SwiftUI

struct TeamView: View {
    @EnvironmentObject var starredTeams: StarredTeams
    @EnvironmentObject var teams: TeamsData
    @EnvironmentObject var games: GamesData

    let teamCode: String
    
    var body: some View {
        let _team = self.teams.getTeam(teamCode)
        let starred = starredTeams.isStarred(teamCode: teamCode)
        VStack(alignment: .center, spacing: 10, content: {
            Text("Svenska Hockey Ligan").fontWeight(.medium)
            TeamLogo(code: teamCode, size: .big)
            Text(_team?.name ?? teamCode).font(.largeTitle).fontWeight(.medium)
            StarButton(starred: starred) {
                if (starred) {
                    starredTeams.removeTeam(teamCode: teamCode)
                } else {
                    starredTeams.addTeam(teamCode: teamCode)
                }
            }
            Spacer()
            List {
                Section(header: Text("Live").font(.headline), content: {
                    ForEach(games.getLiveGames(teamCodes: [teamCode])) { (item) in
                        VStack(alignment: .leading) {
                            HStack() {
                                LiveGame(game: item)
                            }
                        }.padding(EdgeInsets(top: 10, leading: 0, bottom: 10, trailing: 0))
                    }
                })
                Section(header: Text("Coming").font(.headline), content: {
                    ForEach(games.getFutureGames(teamCodes: [teamCode])) { (item) in
                        VStack(alignment: .leading) {
                            HStack() {
                                ComingGame(game: item)
                            }
                        }.padding(EdgeInsets(top: 10, leading: 0, bottom: 10, trailing: 0))
                    }
                })
                Section(header: Text("Played").font(.headline), content: {
                    ForEach(games.getPlayedGames(teamCodes: [teamCode])) { (item) in
                        VStack(alignment: .leading) {
                            HStack() {
                                PlayedGame(game: item)
                            }
                        }.padding(EdgeInsets(top: 10, leading: 0, bottom: 10, trailing: 0))
                    }
                })
            }
            .listStyle(InsetGroupedListStyle())
        })
    }
}

struct StarButton: View {
    var starred: Bool
    var action: () -> Void
    var body: some View {
        Button(action: action, label: {
            Image(systemName: starred ? "star.circle.fill" : "star.circle")
                .foregroundColor(.yellow)
            Text("Favourite").foregroundColor(.white)
        })
        .padding(6)
        .background(Color.gray)
        .cornerRadius(12)
        .buttonStyle(PlainButtonStyle())
    }
}

struct TeamView_Previews: PreviewProvider {
    static var previews: some View {
        let teams = TeamsData()
        teams.teams["LHF"] = Team(code: "LHF", name: "Luleå HF")
        
        return TeamView(teamCode: "LHF")
            .environmentObject(teams)
            .environmentObject(StarredTeams())
            .environmentObject(GamesData(data: [getLiveGame(), getPlayedGame(), getFutureGame()]))
    }
}
