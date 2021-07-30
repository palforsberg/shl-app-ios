//
//  TeamView.swift
//  HockeyPal
//
//  Created by Pål Forsberg on 2021-01-14.
//

import SwiftUI

struct StatsRowSingle: View {
    var left: String
    var right: String
    
    var body: some View {
        HStack() {
            Text(LocalizedStringKey(left)).font(.system(size: 20, design: .rounded)).fontWeight(.semibold).frame(maxWidth: .infinity, alignment: .leading)
            Spacer()
            Text(right).font(.system(size: 20, design: .rounded)).fontWeight(.bold).frame(width: 65, alignment: .trailing)
        }.padding(EdgeInsets(top: 5, leading: 0, bottom: 5, trailing: 0))
    }
}

struct TeamView: View {
    @EnvironmentObject var starredTeams: StarredTeams
    @EnvironmentObject var teams: TeamsData
    @EnvironmentObject var games: GamesData

    let teamCode: String
    let standing: Standing
    
    var body: some View {
        let _team = self.teams.getTeam(teamCode)
        let starred = starredTeams.isStarred(teamCode: teamCode)
        ScrollView {
            LazyVStack(alignment: .center, spacing: 10, content: {
                Text("Swedish Hockey League").fontWeight(.medium)
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
                Group {
                    Text("Season Details").listHeader()
                    GroupedView {
                        Group {
                            StatsRowSingle(left: "Rank", right: "#\(standing.rank)")
                            StatsRowSingle(left: "Points", right: "\(standing.points)")
                            StatsRowSingle(left: "Games Played", right: "\(standing.gp)")
                            StatsRowSingle(left: "Points/Game", right: standing.getPointsPerGame())
                        }.padding(EdgeInsets(top: 0, leading: 10, bottom: 0, trailing: 10))
                    }
                    Spacer()
                }
                if (!games.getLiveGames(teamCodes: [teamCode]).isEmpty) {
                    Group {
                        Text("Live").listHeader()
                        GroupedView {
                            ForEach(games.getLiveGames(teamCodes: [teamCode])) { (item) in
                                LiveGame(game: item)
                            }
                        }
                        Spacer()
                    }
                }
                if (!games.getFutureGames(teamCodes: [teamCode]).isEmpty) {
                    Group {
                        Text("Coming").listHeader()
                        GroupedView {
                            ForEach(games.getFutureGames(teamCodes: [teamCode])) { (item) in
                                ComingGame(game: item)
                            }
                        }
                        Spacer()
                    }
                }
                if (!games.getPlayedGames(teamCodes: [teamCode]).isEmpty) {
                    Group {
                        Text("Played").listHeader()
                        GroupedView {
                            ForEach(games.getPlayedGames(teamCodes: [teamCode])) { (item) in
                                PlayedGame(game: item)
                            }
                        }
                    }
                }
            })
            .background(Color(UIColor.systemGroupedBackground))
        }.background(Color(UIColor.systemGroupedBackground))
    }
}

struct StarButton: View {
    var starred: Bool
    var action: () -> Void
    var body: some View {
        Button(action: action, label: {
            Image(systemName: starred ? "star.circle.fill" : "star.circle")
                .foregroundColor(Color(UIColor.systemYellow))
            Text("Favourite")
        })
        .padding(6)
        .background(Color(UIColor.systemGray5))
        .cornerRadius(12)
        .buttonStyle(PlainButtonStyle())
    }
}

struct TeamView_Previews: PreviewProvider {
    static var previews: some View {
        let teams = TeamsData()
        teams.teams["LHF"] = Team(code: "LHF", name: "Luleå HF")
        
        return TeamView(teamCode: "LHF", standing: Standing(team_code: "LHF", gp: 5, rank: 1, points: 15))
            .environmentObject(teams)
            .environmentObject(StarredTeams())
            .environmentObject(GamesData(data: [getLiveGame(score1: 13, score2: 2), getLiveGame(score1: 4, score2: 99),
                                                getPlayedGame(), getPlayedGame(),
                                                getFutureGame(), getFutureGame()]))
            .environment(\.locale, .init(identifier: "sv"))
    }
}
