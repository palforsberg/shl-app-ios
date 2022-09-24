//
//  GameView.swift
//  HockeyPal
//
//  Created by Pål Forsberg on 2021-01-08.
//

import SwiftUI


struct GameScore: View {
    var s1: Int
    var s2: Int
    var body: some View {
        HStack {
            Text("\(s1)")
                .font(.system(size: 30, design: .rounded))
                .fontWeight(.bold)
                .monospacedDigit()
                .scaledToFit()
                .minimumScaleFactor(0.6)
            Text("-").font(.system(size: 20, design: .rounded))
                .scaledToFit()
                .minimumScaleFactor(0.1)
            Text("\(s2)")
                .font(.system(size: 30, design: .rounded))
                .fontWeight(/*@START_MENU_TOKEN@*/.bold/*@END_MENU_TOKEN@*/)
                .monospacedDigit()
                .scaledToFit()
                .minimumScaleFactor(0.6)
        }
    }
}

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
            TeamLogo(code: teamCode)
                .padding(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
            Text(teamCode)
                .font(.system(size: 24, design: .rounded)).fontWeight(.semibold)
                .starred(starred)
                .scaledToFit()
                .minimumScaleFactor(0.6)
        }
        .frame(width: self.getWidth(), alignment: alignment)
    }
    private func getWidth() -> CGFloat {
        return UIScreen.isMini ? 80.0 : 115.0
    }
}

struct LiveGame2: View {
    var game: Game
    var body: some View {
        HStack {
            VStack {
                TeamLogo(code: game.home_team_code)
                Text("Luleå")
                    .font(.system(size: 14, design: .rounded))
                    .fontWeight(.medium)
                    .starred(false)
                    .scaledToFit()
                    .padding(EdgeInsets(top: -2, leading: 0, bottom: 0, trailing: 0))
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
                TeamLogo(code: game.away_team_code)
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
        VStack(alignment: .center, spacing: -1) {
            HStack {
                TeamAvatar(game.home_team_code, alignment: .center)
                Spacer()
                GameScore(s1: game.home_team_result, s2: game.away_team_result)
                Spacer()
                TeamAvatar(game.away_team_code, alignment: .center)
            }
            Text(LocalizedStringKey(game.status ?? ""))
                .font(.system(size: 18, weight: .semibold, design: .rounded))
                .foregroundColor(Color(UIColor.secondaryLabel))
        }
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
                    .scaledToFit()
                    .minimumScaleFactor(0.6)
                    
                Text("\(game.start_date_time.getFormattedTime())")
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                    .foregroundColor(Color(UIColor.secondaryLabel))
            })
            Spacer()
            TeamAvatar(game.away_team_code, alignment: .center)
        }
    }
}

struct PlayedGame: View {
    var game: Game
    var body: some View {
        let homeLost = game.home_team_result < game.away_team_result
        let awayLost = game.home_team_result > game.away_team_result
        VStack(alignment: .center, spacing: -1) {
            HStack {
                TeamAvatar(game.home_team_code, alignment: .center)
                    .opacity(homeLost ? 0.6 : 1.0)
                Spacer()
                GameScore(s1: game.home_team_result, s2: game.away_team_result)
                Spacer()
                TeamAvatar(game.away_team_code, alignment: .center)
                    .opacity(awayLost ? 0.6 : 1.0)
            }
            Text(LocalizedStringKey(game.start_date_time.getFormattedDate()))
                .font(.system(size: 18, weight: .semibold, design: .rounded))
                .foregroundColor(Color(UIColor.secondaryLabel))
        }
    }
}

struct SeasonView: View {
    @EnvironmentObject var starredTeams: StarredTeams
    @EnvironmentObject var gamesData: GamesData
    @EnvironmentObject var settings: Settings
    
    @State var lastReload = Date(timeIntervalSince1970: 0)
    
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
                                    .padding(EdgeInsets(top: 10, leading: -10, bottom: 10, trailing: -10))
                            }
                        }
                    }
                }
                if !futureGames.isEmpty {
                    Section(header: Text("Coming").listHeader()) {
                        ForEach(futureGames) { (item) in
                            NavigationLink(destination: GamesStatsView(game: item)) {
                                ComingGame(game: item)
                                    .id(arc4random())
                                    .padding(EdgeInsets(top: 10, leading: -10, bottom: 10, trailing: -10))
                            }
                        }
                    }
                }
                if !playedGames.isEmpty {
                    Section(header: Text("Played_param \(settings.getFormattedPrevSeason())").listHeader()) {
                        ForEach(playedGames) { (item) in
                            NavigationLink(destination: GamesStatsView(game: item)) {
                                PlayedGame(game: item)
                                    .id(arc4random())
                                    .padding(EdgeInsets(top: 10, leading: -10, bottom: 10, trailing: -10))
                            }
                        }
                    }
                }
            }
            .refreshable {
                let tenSeconds: Double = 10
                let throttled = await self.reloadThrottledWithInterval(tenSeconds)
                if throttled {
                    do {
                        try await Task.sleep(nanoseconds: 500 * 1_000_000)
                    } catch {}
                }
            }
            .task { // runs before view appears
                debugPrint("[SEASONVIEW] view did appear")
                await self.reloadThrottledWithInterval(15 * 60)
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
                debugPrint("[SEASONVIEW] settings.$season")
                await self.reloadData()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .onGameNotification)) { _ in
            Task {
                debugPrint("[SEASONVIEW] onGameNotification")
                await self.reloadData()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
            debugPrint("[SEASONVIEW] applicationWillEnterForeground")
            Task {
                await self.reloadThrottledWithInterval(15 * 60)
            }
        }
    }
    
    func reloadThrottledWithInterval(_ throttling: TimeInterval) async -> Bool {
        guard -lastReload.timeIntervalSinceNow > throttling else {
            debugPrint("[SEASONVIEW] do not update \(throttling) > \(-lastReload.timeIntervalSinceNow)")
            return true
        }
        debugPrint("[SEASONVIEW] do update")
        await self.reloadData()
        return false
    }

    func reloadData() async {
        self.lastReload = Date.now
        if let gd = await provider?.getGames(season: settings.season) {
            gamesData.set(data: gd)
        } else {
            self.lastReload = Date(timeIntervalSince1970: 0)
        }
    }
}

struct SeasonView_Previews: PreviewProvider {
    static var previews: some View {
        let gamesData = GamesData(data: [
                                    getLiveGame(t1: "MIF", score1: 1, t2: "TIK", score2: 3, status: "Intermission"),
                                    getLiveGame(t1: "LHF", score1: 4, t2: "FHC", score2: 2),
                                                       
                                    getPlayedGame(t1: "LHF", s1: 4, t2: "FBK", s2: 1),
                                    getPlayedGame(t1: "SAIK", s1: 3, t2: "TIK", s2: 1),
                
                                    getFutureGame(t1: "LHF", t2: "HV71", days: 1),
                                    getFutureGame(t1: "LHF", t2: "TIK", days: 2)])
        let starredTeams = StarredTeams()
        starredTeams.addTeam(teamCode: "LHF")
        starredTeams.addTeam(teamCode: "TIK")
        
        return SeasonView(provider: nil)
            .environmentObject(starredTeams)
            .environmentObject(gamesData)
            .environmentObject(getTeamsData())
            .environmentObject(Settings())
            .environment(\.locale, .init(identifier: "sv"))
    }
}


