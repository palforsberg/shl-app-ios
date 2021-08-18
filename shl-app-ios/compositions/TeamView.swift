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
        }.padding(EdgeInsets(top: 4, leading: 0, bottom: 4, trailing: 0))
    }
}

struct TeamView: View {
    @EnvironmentObject var starredTeams: StarredTeams
    @EnvironmentObject var teams: TeamsData
    @EnvironmentObject var games: GamesData
    @EnvironmentObject var settings: Settings

    let teamCode: String
    let standing: Standing
    
    var body: some View {
        let _team = self.teams.getTeam(teamCode)
        let starred = starredTeams.isStarred(teamCode: teamCode)
        let liveGames = games.getLiveGames(teamCodes: [teamCode])
        let futureGames = games.getFutureGames(teamCodes: [teamCode])
        let playedGames = games.getPlayedGames(teamCodes: [teamCode])
        ScrollView {
            LazyVStack(alignment: .center, spacing: 10) {
                Group {
                    Spacer(minLength: 5)
                    Text("Swedish Hockey League").fontWeight(.semibold).font(.system(size: 15, design: .rounded))
                            .foregroundColor(Color(UIColor.secondaryLabel))
                    Spacer(minLength: 0)
                }
                TeamLogo(code: teamCode, size: .big)
                Text(_team?.name ?? teamCode)
                    .font(.largeTitle).fontWeight(.medium)
                    .starred(starred)
                StarButton(starred: starred) {
                    if (starred) {
                        starredTeams.removeTeam(teamCode: teamCode)
                    } else {
                        starredTeams.addTeam(teamCode: teamCode)
                    }
                }
                Spacer()
                Group {
                    GroupedView(title: "Season_param \(settings.getFormattedPrevSeason())" ) {
                        VStack {
                            StatsRowSingle(left: "Rank", right: "#\(standing.rank)")
                            StatsRowSingle(left: "Points", right: "\(standing.points)")
                            StatsRowSingle(left: "Games Played", right: "\(standing.gp)")
                            StatsRowSingle(left: "Points/Game", right: standing.getPointsPerGame())
                            StatsRowSingle(left: "Goal Diff", right: "\(standing.diff)")
                        }.padding(EdgeInsets(top: 10, leading: 14, bottom: 10, trailing: 14))
                    }
                    Spacer()
                }
                if (!liveGames.isEmpty) {
                    Group {
                        GroupedView(title: "Live") {
                            ForEach(liveGames) { (item) in
                                LiveGame(game: item)
                                if (item != liveGames.last) {
                                    Divider()
                                }
                            }
                        }
                        Spacer()
                    }
                }
                if (!futureGames.isEmpty) {
                    Group {
                        GroupedView(title: "Coming") {
                            ForEach(futureGames) { (item) in
                                ComingGame(game: item)
                                if (item != futureGames.last) {
                                    Divider()
                                }
                            }
                        }
                        Spacer()
                    }
                }
                if (!playedGames.isEmpty) {
                    Group {
                        GroupedView(title: "Played_param \(settings.getFormattedPrevSeason())") {
                            ForEach(playedGames) { (item) in
                                PlayedGame(game: item)
                                if (item != playedGames.last) {
                                    Divider()
                                }
                            }
                        }
                    }
                }
            }
            .background(Color(UIColor.systemGroupedBackground))
        }.background(Color(UIColor.systemGroupedBackground))
        .navigationBarTitle("", displayMode: .inline)
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
        
        return Group {
            TeamView(teamCode: "LHF", standing: getStanding("LHF", rank: 1))
                .environmentObject(teams)
                .environmentObject(StarredTeams())
                .environmentObject(GamesData(data: [getLiveGame(t1: "LHF", score1: 13, t2: "FHC", score2: 2),
                                                    getLiveGame(t1: "LHF", score1: 13, t2: "FHC", score2: 2),
                                                    getPlayedGame(), getPlayedGame(),
                                                    getFutureGame(), getFutureGame()]))
                .environmentObject(Settings())
                .environment(\.locale, .init(identifier: "sv"))
            TeamView(teamCode: "LHF", standing: getStanding("LHF", rank: 1))
                .environmentObject(teams)
                .environmentObject(StarredTeams())
                .environmentObject(GamesData(data: [getLiveGame(t1: "LHF", score1: 13, t2: "FHC", score2: 2),
                                                    getLiveGame(t1: "LHF", score1: 13, t2: "FHC", score2: 2),
                                                    getPlayedGame(), getPlayedGame(),
                                                    getFutureGame(), getFutureGame()]))
                .environmentObject(Settings())
                .environment(\.locale, .init(identifier: "sv"))
        }
    }
}
