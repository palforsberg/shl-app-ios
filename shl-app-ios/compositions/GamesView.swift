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
            Text(teamCode).font(.system(size: 28)).fontWeight(.medium)
        }
        .frame(width: 115, height: 40, alignment: alignment)
        
    }
}

struct LiveGame: View {
    var game: Game
    var body: some View {
        TeamLogo(code: game.home_team_code)
        Text(game.home_team_code)
        Text("-")
        TeamLogo(code: game.away_team_code)
        Text(game.away_team_code)
        Spacer()
        Text("\(game.home_team_result) - \(game.away_team_result)")
            .multilineTextAlignment(.trailing)
    }
}

struct ComingGame: View {
    var game: Game
    var body: some View {
        HStack {
            TeamAvatar(game.home_team_code)
            TeamAvatar(game.away_team_code)
            Spacer()
            VStack(alignment: .center, spacing: /*@START_MENU_TOKEN@*/nil/*@END_MENU_TOKEN@*/, content: {
                Text("\(game.start_date_time.getFormattedDate())".uppercased())
                    .fontWeight(.semibold)
                    .foregroundColor(Color.init(Color.RGBColorSpace.sRGB, white: 0.4, opacity: 1.0))
                    .font(.system(size: 15))
                    
                Text("\(game.start_date_time.getFormattedTime())")
                    .font(.system(size: 15))
                    .foregroundColor(Color.init(Color.RGBColorSpace.sRGB, white: 0.4, opacity: 1.0))
            })
        }
    }
}

struct ComingGame_Previews: PreviewProvider {
    static var previews: some View {
        ComingGame(game: Game(game_id: 1, away_team_code: "FHC", away_team_result: 2, home_team_code: "LHF", home_team_result: 3, start_date_time: Date(), played: false))
            .environment(\.locale, .init(identifier: "sv"))
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
            Text(game.start_date_time.getFormattedDate())
                .font(.system(size: 18))
                .fontWeight(/*@START_MENU_TOKEN@*/.bold/*@END_MENU_TOKEN@*/)
                .foregroundColor(Color.init(white: 0.6))
        })
    }
}

struct PlayedGame_Previews: PreviewProvider {
    static var previews: some View {
        PlayedGame(game: Game(game_id: 1, away_team_code: "FHC", away_team_result: 2, home_team_code: "LHF", home_team_result: 3, start_date_time: Date(), played: false))
            .environment(\.locale, .init(identifier: "sv"))
    }
}

struct GamesView: View {
    @EnvironmentObject var starredTeams: StarredTeams
    
    @State var liveGames = [Game]()
    @State var futureGames = [Game]()
    @State var playedGames = [Game]()
    
    var body: some View {
        NavigationView {
            List {
                if (!liveGames.isEmpty) {
                    Section(header: Text("Live").font(.headline), content: {
                        ForEach(liveGames) { (item) in
                            VStack(alignment: .leading) {
                                HStack() {
                                    LiveGame(game: item)
                                }
                            }.padding(EdgeInsets(top: 10, leading: 0, bottom: 10, trailing: 0))
                        }
                    })
                }
                Section(header: Text("Coming").font(.headline), content: {
                    ForEach(futureGames) { (item) in
                        VStack(alignment: .leading) {
                            HStack() {
                                ComingGame(game: item)
                            }
                        }.padding(EdgeInsets(top: 10, leading: 0, bottom: 10, trailing: 0))
                    }
                })
                Section(header: Text("Played").font(.headline), content: {
                    ForEach(playedGames) { (item) in
                        VStack(alignment: .leading) {
                            HStack() {
                                PlayedGame(game: item)
                            }
                        }.padding(EdgeInsets(top: 10, leading: 0, bottom: 10, trailing: 0))
                    }
                })
            }
            .listStyle(InsetGroupedListStyle())
            .navigationBarTitle(Text("Games"))
            .onAppear(perform: {
                getGames { (result) in
                    let teamCodes = starredTeams.get()
                    self.futureGames = result.getFutureGames(teamCodes: teamCodes)
                    self.liveGames = result.getLiveGames(teamCodes: teamCodes)
                    self.playedGames = result.getPlayedGames(teamCodes: teamCodes)
                }
            })
            Color.gray
        }
    }
}

struct GamesView_Previews: PreviewProvider {
    static var previews: some View {
        GamesView()
            .environment(\.locale, .init(identifier: "sv"))
    }
}
