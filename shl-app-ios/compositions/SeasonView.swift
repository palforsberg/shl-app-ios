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
    @EnvironmentObject var starredTeams: StarredTeams
    
    init(_ teamCode: String) {
        self.teamCode = teamCode
    }

    init(_ teamCode: String, alignment: Alignment) {
        self.teamCode = teamCode
        self.alignment = alignment
    }
    
    var body: some View {
        let starred = starredTeams.isStarred(teamCode: teamCode)
        HStack {
            TeamLogo(code: teamCode, size: LogoSize.small)
                .padding(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
            Text(teamCode)
                .font(.system(size: 24, design: .rounded)).fontWeight(.semibold)
                .starred(starred)
                .scaledToFit()
                .minimumScaleFactor(0.6)
        }
        .frame(width: 115, height: 40, alignment: alignment)
        
    }
}

struct LiveGame2: View {
    var game: Game
    var body: some View {
        HStack {
            VStack {
                TeamLogo(code: game.home_team_code, size: .small)
                Text("Luleå")
                    .font(.system(size: 14, design: .rounded))
                    .fontWeight(.medium)
                    .starred(false)
                    .scaledToFit()
                    .padding(EdgeInsets(top: -2, leading: 0, bottom: 0, trailing: 0    ))
                    .minimumScaleFactor(0.8)
                    
            }.frame(width: /*@START_MENU_TOKEN@*/100/*@END_MENU_TOKEN@*/, height: 50)
            Spacer()
            Text("\(game.home_team_result)")
                .font(.system(size: 30))
                .fontWeight(/*@START_MENU_TOKEN@*/.bold/*@END_MENU_TOKEN@*/)
            Text("-")
            Text("\(game.away_team_result)")
                .font(.system(size: 30))
                .fontWeight(.bold)
            Spacer()
            VStack {
                TeamLogo(code: game.away_team_code, size: .small)
                Text("Frölunda")
                    .font(.system(size: 14, design: .rounded))
                    .fontWeight(.medium)
                    .starred(false)
                    .scaledToFit()
                    .padding(EdgeInsets(top: -2, leading: 0, bottom: 0, trailing: 0    ))
                    .minimumScaleFactor(0.6)
                    
            }.frame(width: 100, height: 50)
        }.padding(EdgeInsets(top: 10, leading: -10, bottom: 10, trailing: -10))
    }
}


struct LiveGame: View {
    var game: Game
    var body: some View {
        HStack {
            TeamAvatar(game.home_team_code, alignment: .center)
            Spacer()
            Text("\(game.home_team_result)")
                .font(.system(size: 30, design: .rounded))
                .fontWeight(/*@START_MENU_TOKEN@*/.bold/*@END_MENU_TOKEN@*/)
            Text("-").font(.system(size: 20, design: .rounded))
            Text("\(game.away_team_result)")
                .font(.system(size: 30, design: .rounded))
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
                    .foregroundColor(Color(UIColor.secondaryLabel))
                    .font(.system(size: 18, design: .rounded))
                    
                Text("\(game.start_date_time.getFormattedTime())")
                    .font(.system(size: 15, design: .rounded))
                    .foregroundColor(Color(UIColor.secondaryLabel))
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
                    .opacity(homeLost ? 0.6 : 1.0)
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
                    .opacity(awayLost ? 0.6 : 1.0)
            }
            Text(LocalizedStringKey(game.start_date_time.getFormattedDate()))
                .font(.system(size: 18, design: .rounded))
                .fontWeight(/*@START_MENU_TOKEN@*/.bold/*@END_MENU_TOKEN@*/)
                .foregroundColor(Color.init(white: 0.6))
        }).padding(EdgeInsets(top: 10, leading: -10, bottom: 10, trailing: -10))
    }
}

struct SeasonView: View {
    @EnvironmentObject var starredTeams: StarredTeams
    @EnvironmentObject var gamesData: GamesData
    @EnvironmentObject var settings: Settings
    
    @State var reloading = false
    
    var provider: DataProvider?
    
    var body: some View {
        let teamCodes = settings.onlyStarred ? starredTeams.starredTeams : []
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
                    Section(header: Text("Played_param \(settings.getFormattedPrevSeason())").listHeader()) {
                        ForEach(playedGames) { (item) in
                            NavigationLink(destination: GamesStatsView(game: item)) {
                                PlayedGame(game: item)
                            }
                        }
                    }
                }
            }
            .refreshable {
                guard !self.reloading else {
                    do {
                        try await Task.sleep(nanoseconds: 500 * 1_000_000)
                    } catch {}
                    return
                }
                await self.reloadData()
            }
            .id(settings.season) // makes sure list is recreated when rerendered. To take care of reuse cell issues
            .listStyle(InsetGroupedListStyle())
            .navigationBarTitle(Text("Matches"))
            .navigationBarItems(trailing: NavigationLink(destination: SettingsView()) {
                Image(systemName: "gearshape.circle").frame(width: 44, height: 44, alignment: .trailing)
            })
        }
        .onReceive(settings.$season) { _ in
            Task {
                await self.reloadData()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .onGameNotification)) { _ in
            Task {
                await self.reloadData()
            }
        }
    }
    
    func reloadData() async {
        self.reloading = true
        if let gd = await provider?.getGames(season: settings.season) {
            gamesData.set(data: gd)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 10) {
            self.reloading = false
        }
    }
}

struct SeasonView_Previews: PreviewProvider {
    static var previews: some View {
        let gamesData = GamesData(data: [
                                    getLiveGame(t1: "MIF", score1: 1, t2: "TIK", score2: 3),
                                    getLiveGame(t1: "LHF", score1: 4, t2: "FHC", score2: 2),
                                                       
                                    getPlayedGame(t1: "LHF", s1: 4, t2: "FBK", s2: 1),
                                    getPlayedGame(t1: "LIF", s1: 3, t2: "TIK", s2: 1),
                
                                    getFutureGame(t1: "LHF", t2: "TIK"),
                                    getFutureGame()])
        let starredTeams = StarredTeams()
        starredTeams.addTeam(teamCode: "LHF")
        
        return SeasonView(
                  provider: nil)
            .environmentObject(starredTeams)
            .environmentObject(gamesData)
            .environmentObject(Settings())
            .environment(\.locale, .init(identifier: "sv"))
    }
}
