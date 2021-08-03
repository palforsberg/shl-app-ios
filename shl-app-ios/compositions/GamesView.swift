//
//  GameView.swift
//  HockeyPal
//
//  Created by Pål Forsberg on 2021-01-08.
//

import SwiftUI


struct TeamAvatar: View {
    var teamCode: String
    var alignment = Alignment.leading
    
    init(_ teamCode: String) {
        self.teamCode = teamCode
    }

    init(_ teamCode: String, alignment: Alignment) {
        self.teamCode = teamCode
        self.alignment = alignment
    }
    
    var body: some View {
        HStack {
            TeamLogo(code: teamCode, size: LogoSize.small)
                .padding(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
            Text(teamCode).font(.system(size: 24, design: .rounded)).fontWeight(.semibold)
                .scaledToFit()
                .minimumScaleFactor(0.8)
        }
        .frame(width: 115, height: 40, alignment: alignment)
        
    }
}

struct LiveGame: View {
    var game: Game
    var body: some View {
        HStack {
            TeamAvatar(game.home_team_code, alignment: .center)
            Spacer()
            Text("\(game.home_team_result)")
                .font(.system(size: 30))
                .fontWeight(/*@START_MENU_TOKEN@*/.bold/*@END_MENU_TOKEN@*/)
            Text("-")
            Text("\(game.away_team_result)")
                .font(.system(size: 30))
                .fontWeight(/*@START_MENU_TOKEN@*/.bold/*@END_MENU_TOKEN@*/)
            Spacer()
            TeamAvatar(game.away_team_code, alignment: .center)
        }.padding(EdgeInsets(top: 10, leading: -10, bottom: 10, trailing: -10))
    }
}

struct ComingGame: View {
    var game: Game
    var body: some View {
        HStack {
            TeamAvatar(game.home_team_code, alignment: .center)
            Spacer()
            VStack(alignment: .center, spacing: /*@START_MENU_TOKEN@*/nil/*@END_MENU_TOKEN@*/, content: {
                Text(LocalizedStringKey(game.start_date_time.getFormattedDate()))
                    .fontWeight(.semibold)
                    .foregroundColor(Color.init(Color.RGBColorSpace.sRGB, white: 0.4, opacity: 1.0))
                    .font(.system(size: 18, design: .rounded))
                    
                Text("\(game.start_date_time.getFormattedTime())")
                    .font(.system(size: 15, design: .rounded))
                    .foregroundColor(Color.init(Color.RGBColorSpace.sRGB, white: 0.4, opacity: 1.0))
            })
            Spacer()
            TeamAvatar(game.away_team_code, alignment: .center)
        }.padding(EdgeInsets(top: 10, leading: -10, bottom: 10, trailing: -10))
    }
}

struct PlayedGame: View {
    var game: Game
    var body: some View {
        let homeLost = game.home_team_result < game.away_team_result
        let awayLost = game.home_team_result > game.away_team_result
        VStack(alignment: .center, spacing: -1, content: {
            HStack {
                TeamAvatar(game.home_team_code, alignment: .center)
                    .opacity(homeLost ? 0.5 : 1.0)
                Spacer()
                Text("\(game.home_team_result)")
                    .font(.system(size: 30))
                    .fontWeight(/*@START_MENU_TOKEN@*/.bold/*@END_MENU_TOKEN@*/)
                Text("-")
                Text("\(game.away_team_result)")
                    .font(.system(size: 30))
                    .fontWeight(/*@START_MENU_TOKEN@*/.bold/*@END_MENU_TOKEN@*/)
                Spacer()
                TeamAvatar(game.away_team_code, alignment: .center)
                    .opacity(awayLost ? 0.5 : 1.0)
            }
            Text(LocalizedStringKey(game.start_date_time.getFormattedDate()))
                .font(.system(size: 18, design: .rounded))
                .fontWeight(/*@START_MENU_TOKEN@*/.bold/*@END_MENU_TOKEN@*/)
                .foregroundColor(Color.init(white: 0.6))
        }).padding(EdgeInsets(top: 10, leading: -10, bottom: 10, trailing: -10))
    }
}

struct GamesView: View {
    @EnvironmentObject var starredTeams: StarredTeams
    @EnvironmentObject var season: Season
    @EnvironmentObject var gamesData: GamesData
    
    var provider: DataProvider?
    
    var body: some View {
        let teamCodes = starredTeams.starredTeams
        let liveGames = gamesData.getLiveGames(teamCodes: teamCodes)
        let futureGames = gamesData.getFutureGames(teamCodes: teamCodes)
        let playedGames = gamesData.getPlayedGames(teamCodes: teamCodes)

        NavigationView {
            List {
                if (!liveGames.isEmpty) {
                    Section(header: Text("Live").listHeader()) {
                        ForEach(liveGames) { (item) in
                            NavigationLink(destination: GamesStatsView(game: item)) {
                                LiveGame(game: item)
                            }
                        }
                    }
                }
                if !futureGames.isEmpty {
                    Section(header: Text("Coming").listHeader()) {
                        ForEach(futureGames) { (item) in
                            NavigationLink(destination: GamesStatsView(game: item)) {
                                ComingGame(game: item)
                            }
                        }
                    }
                }
                if !playedGames.isEmpty {
                    Section(header: Text("Played_param \(season.getFormattedPrevSeason())").listHeader()) {
                        ForEach(playedGames) { (item) in
                            NavigationLink(destination: GamesStatsView(game: item)) {
                                PlayedGame(game: item)
                            }
                        }
                    }
                }
            }
            .listStyle(InsetGroupedListStyle())
            .navigationBarTitle(Text("Matches"))
            .navigationBarItems(trailing:NavigationLink(destination: SettingsView()) {
                                         Image(systemName: "gear")
                                     })
        }.onReceive(season.$season, perform: { _ in
            provider?.getGames(season: season.season) { gd in
                gamesData.set(data: gd)
            }
        })
    }
}

struct GamesView_Previews: PreviewProvider {
    static var previews: some View {
        let gamesData = GamesData(data: [getLiveGame(), getLiveGame(),
                                         getPlayedGame(), getPlayedGame(),
                                         getFutureGame(), getFutureGame()])
        let starredTeams = StarredTeams()
        starredTeams.addTeam(teamCode: "LHF")
        
        return GamesView(
                  provider: nil)
            .environmentObject(starredTeams)
            .environmentObject(Season())
            .environmentObject(gamesData)
            .environment(\.locale, .init(identifier: "sv"))
    }
}
