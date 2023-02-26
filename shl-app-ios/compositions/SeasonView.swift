//
//  GameView.swift
//  HockeyPal
//
//  Created by Pål Forsberg on 2021-01-08.
//

import SwiftUI
import WidgetKit


struct GameScore: View {
    var s1: Int
    var s2: Int
    var body: some View {
        HStack {
            Text("\(s1)")
                .font(.system(size: 30, weight: .bold, design: .rounded))
                .monospacedDigit()
                .scaledToFit()
                .minimumScaleFactor(0.6)
            Text("-").font(.system(size: 22, weight: .black, design: .rounded))
                .scaledToFit()
                .minimumScaleFactor(0.1)
            Text("\(s2)")
                .font(.system(size: 30, weight: .bold, design: .rounded))
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
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .starred(starred)
                .scaledToFit()
                .minimumScaleFactor(0.6)
        }
        .frame(width: self.getWidth(), alignment: alignment)
        .opacity(self.teamCode == "TBD" ? 0.4 : 1.0)
    }
    private func getWidth() -> CGFloat {
        return UIScreen.isMini ? 80.0 : 115.0
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
            HStack(spacing: 4) {
                if let s = game.status {
                    Text(LocalizedStringKey(s))
                }
                if let s = game.gametime, game.getStatus()?.isGameTimeApplicable() ?? false {
                    Text("•")
                    Text(s)
                }
            }
            .foregroundColor(Color(uiColor: .secondaryLabel))
            .font(.system(size: 16, weight: .bold, design: .rounded))
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
                    .font(.system(size: 17, weight: .semibold, design: .rounded))
                    .scaledToFit()
                    .minimumScaleFactor(0.6)
                Text("\(game.start_date_time.getFormattedTime())")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundColor(Color(UIColor.secondaryLabel))
            })
            .offset(y: 1)
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
        VStack(alignment: .center, spacing: 0) {
            HStack {
                TeamAvatar(game.home_team_code, alignment: .center)
                    .opacity(homeLost ? 0.6 : 1.0)
                Spacer()
                GameScore(s1: game.home_team_result, s2: game.away_team_result)
                Spacer()
                TeamAvatar(game.away_team_code, alignment: .center)
                    .opacity(awayLost ? 0.6 : 1.0)
            }
            HStack(spacing: 4) {
                if game.penalty_shots {
                    Text("shootout")
                    Text("•")
                } else if game.overtime {
                    Text("overtime")
                    Text("•")
                }
                Text(LocalizedStringKey(game.start_date_time.getFormattedDate()))
            }.font(.system(size: 16, weight: .bold, design: .rounded))
            .foregroundColor(Color(UIColor.secondaryLabel))
        }
    }
}


struct WidgetPromo: View {
    @AppStorage("widget.promo.2023.removed.7")
    var removed = false
    
    var body: some View {
        if !removed {
            Section {
                ZStack {
                    Group {
                        GeometryReader { geo in
                            Puck(geo: geo, scale: 0.15).pos(0.9, 0.2)
                            Puck(geo: geo, scale: 0.15).pos(0.85, 0.6)
                            Puck(geo: geo, scale: 0.15).pos(0.95, 0.8)
                        }
                    }
                    HStack(spacing: 15) {
                        Image(uiImage: UIImage(named: "TeamWidget")!)
                            .resizable()
                            .scaledToFit()
                            .rotation3DEffect(.degrees(10), axis: (x: 0.0, y: 1.0, z: 0.0))
                            .frame(width: 80)
                        VStack(alignment: .leading, spacing: 5) {
                            Text("Pucken Widgets!")
                                .font(.system(size: 18, weight: .heavy, design: .rounded))
                            Text("WIDGETPROMO.BODY")
                                .font(.system(size: 14, weight: .heavy, design: .rounded))
                        }
                        Spacer()
                        Button(action: {
                            print("Remove WidgetPromo")
                            withAnimation {
                                removed = true
                            }
                        }, label: {
                            Image(systemName: "xmark")
                                .font(.system(size: 18, weight: .heavy))
                        }).foregroundColor(Color(uiColor: .label))
                    }
                    .padding(EdgeInsets(top: 10, leading: 0, bottom: 10, trailing: 0))
                }
            }.transition(.scale)
        }
    }
}


struct SeasonView: View {
    @EnvironmentObject var starredTeams: StarredTeams
    @EnvironmentObject var gamesData: GamesData
    @EnvironmentObject var settings: Settings
    
    var provider: DataProvider?
    
    var body: some View {
        let teamCodes = settings.onlyStarred ? starredTeams.starredTeams : []
        let liveGames = gamesData.getLiveGames(teamCodes: teamCodes, starred: starredTeams.starredTeams)
        let futureGames = gamesData.getFutureGames(teamCodes: teamCodes, starred: starredTeams.starredTeams)
        let playedGames = gamesData.getPlayedGames(teamCodes: teamCodes)

        NavigationView {
            List {
                WidgetPromo()
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
                await self.reloadData(5)
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
                let _ = await self.reloadData(1)
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .onGameNotification)) { _ in
            Task {
                debugPrint("[SEASONVIEW] onGameNotification")
                await self.reloadData(0)
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
            debugPrint("[SEASONVIEW] applicationWillEnterForeground")
            Task {
                await self.reloadData(15 * 60)
            }
        }
    }

    func reloadData(_ throttling: TimeInterval) async {
        let maxAge = self.gamesData.getLiveGames(teamCodes: []).count > 0 ? 2 : throttling
        
        if let gd = await provider?.getGames(season: settings.season, fetchType: .throttled, maxAge: maxAge) {
            if let games = gd.entries {
                gamesData.set(data: games)
            }
            if gd.type == .api {
               WidgetCenter.shared.reloadAllTimelines()
               debugPrint("[SEASON] reload widgets")
            }
        }
    }
}

struct SeasonView_Previews: PreviewProvider {
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
        
        return SeasonView(provider: nil)
            .environmentObject(starredTeams)
            .environmentObject(gamesData)
            .environmentObject(getTeamsData())
            .environmentObject(Settings())
            .environment(\.locale, .init(identifier: "sv"))
    }
}


