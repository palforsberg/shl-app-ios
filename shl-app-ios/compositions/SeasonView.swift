//
//  GameView.swift
//  HockeyPal
//
//  Created by Pål Forsberg on 2021-01-08.
//

import SwiftUI
import WidgetKit

struct BorderShine<Content: View>: View {
    @State var animating = false
    @ViewBuilder var content: () -> Content
    
    var body: some View {
        let gradient = Gradient(stops: [
            .init(color: Color(uiColor: UIColor.secondarySystemGroupedBackground), location: 0.05),
            .init(color: Color(uiColor: .secondaryLabel), location: 0.1),
            .init(color: Color(uiColor: .secondaryLabel), location: 0.9),
            .init(color: Color(uiColor: UIColor.secondarySystemGroupedBackground), location: 0.95)
        ])
        let angularGradient = AngularGradient(gradient: gradient, center: .center, angle: .degrees(self.animating ? 360 : 0))
            
        let border = Rectangle()
            .fill(angularGradient)
            .mask(Capsule().stroke(lineWidth: 1))
        
        content()
            .padding(EdgeInsets(top: 3, leading: 6, bottom: 3, trailing: 6))
            .overlay(border)
            .onAppear {
                withAnimation(.linear(duration: 5.0).repeatForever(autoreverses: false)) {
                    self.animating = true
                }
            }
    }
}

struct GameScore: View {
    var s1: Int
    var s2: Int
    var body: some View {
        HStack(alignment: .center, spacing: 8) {
            Text("\(s1)")
            Text(":")
                .font(.system(size: 24, weight: .heavy, design: .rounded))
                .offset(y: -2)
            Text("\(s2)")
        }
        .font(.system(size: 28, weight: .heavy, design: .rounded))
        .monospacedDigit()
        .scaledToFit()
        .minimumScaleFactor(0.6)
    }
}

struct TeamAvatar: View {
    var teamCode: String
    var alignment = Alignment.leading
    @EnvironmentObject var starredTeams: StarredTeams
    @EnvironmentObject var teamsData: TeamsData
    
    init(_ teamCode: String) {
        self.teamCode = teamCode
    }

    init(_ teamCode: String, alignment: Alignment) {
        self.teamCode = teamCode
        self.alignment = alignment
    }
    
    var body: some View {
        let starred = starredTeams.isStarred(teamCode: teamCode)
        let text = self.teamsData.getDisplayCode(teamCode)
        HStack {
            TeamLogo(code: teamCode)
            Text(text)
                .rounded(size: text.count > 3 ? 21 : 22, weight: .heavy)
                .starred(starred)
                .foregroundColor(Color(uiColor: .label))
                .padding(.leading, getOffsetX())
                .scaledToFit()
                .minimumScaleFactor(0.6)
    
        }
        .frame(width: 100, alignment: alignment)
        .opacity(self.teamCode == "TBD" ? 0.4 : 1.0)
    }
    
    func getOffsetX() -> CGFloat {
        switch teamCode {
        case "MODO": return -8
        case "HV71": return -3
        default: return 0
        }
    }
}


struct PickedLabel: View {
    var picked: Bool
    var body: some View {
        Text("PICKED")
            .rounded(size: 10, weight: .heavy)
            .foregroundColor(Color(uiColor: .tertiaryLabel))
            .padding(0)
            .opacity(picked ? 1 : 0)
    }
}
struct LiveGame: View {
    @EnvironmentObject var pickemData: PickemData
    
    var game: Game
    
    var body: some View {
        let pick = pickemData.get(game.game_uuid)
        VStack(alignment: .center, spacing: 4) {
            HStack(spacing: 18) {
                TeamAvatar(game.home_team_code, alignment: .trailing)
                GameScore(s1: game.home_team_result, s2: game.away_team_result)
                TeamAvatar(game.away_team_code, alignment: .leading)
            }
            HStack {
                PickedLabel(picked: pick?.pickedTeam == game.home_team_code)
                /*
                VStack(alignment: .trailing) {
                    Text("SOG").rounded(size: 12, weight: .semibold) +
                    Text(" 12").rounded(size: 12, weight: .heavy)
                    Text("PIM").rounded(size: 12, weight: .semibold) +
                    Text(" 12").rounded(size: 12, weight: .heavy)
                }.monospacedDigit()
                 */

                HStack(spacing: 2) {
                    if let s = game.status {
                        Text(LocalizedStringKey(s))
                    }
                    if let s = game.gametime, game.getStatus()?.isGameTimeApplicable() ?? false {
                        Text("•")
                        Text(s)
                    }
                }
                .padding(.leading, 20).padding(.trailing, 20)

                PickedLabel(picked: pick?.pickedTeam == game.away_team_code)
/*                VStack(alignment: .leading) {
                    Text("12 ").rounded(size: 12, weight: .heavy) +
                    Text("SOG").rounded(size: 12, weight: .semibold)
                    
                    Text("12 ").rounded(size: 12, weight: .heavy) +
                    Text("PIM").rounded(size: 12, weight: .semibold)
                }.monospacedDigit()
 */
            }
            .foregroundColor(Color(uiColor: .secondaryLabel))
            .font(.system(size: 14, weight: .bold, design: .rounded))
        }.frame(maxWidth: .infinity)
    }
}

struct ComingGame: View {
    @EnvironmentObject var pickemData: PickemData
    var game: Game
    var body: some View {
        let pick = pickemData.get(game.game_uuid)
        VStack(alignment: .center, spacing: 2) {
            HStack(spacing: 18) {
                TeamAvatar(game.home_team_code, alignment: .trailing)
                GameScore(s1: 0, s2: 0)
                    .opacity(0.1)
                TeamAvatar(game.away_team_code, alignment: .leading)
            }
            HStack(spacing: 18) {

                PickedLabel(picked: pick?.pickedTeam == game.home_team_code)
                
                HStack(spacing: 2) {
                    Text(LocalizedStringKey(game.start_date_time.getFormattedDate()))
                        .scaledToFit()
                        .minimumScaleFactor(0.6)
                    Text("•")
                    Text("\(game.start_date_time.getFormattedTime())")
                }
                
                PickedLabel(picked: pick?.pickedTeam == game.away_team_code)
            }
            .font(.system(size: 14, weight: .bold, design: .rounded))
            .foregroundColor(Color(UIColor.secondaryLabel))
        }.frame(maxWidth: .infinity)
    }
}

struct PlayedGame: View {
    @EnvironmentObject var pickemData: PickemData
    
    var game: Game

    var body: some View {
        let pick = pickemData.get(game.game_uuid)
        let homeLost = game.home_team_result < game.away_team_result
        VStack(alignment: .center, spacing: 0) {
            HStack(spacing: 18) {
                TeamAvatar(game.home_team_code, alignment: .trailing)
                    .opacity(homeLost ? 0.6 : 1.0)
                GameScore(s1: game.home_team_result, s2: game.away_team_result)
                TeamAvatar(game.away_team_code, alignment: .leading)
                    .opacity(homeLost ? 1.0 : 0.6)
            }
            HStack(spacing: 18) {
                PickedLabel(picked: pick?.pickedTeam == game.home_team_code)
                
                HStack(spacing: 4) {
                    if game.shootout {
                        Text("Shootout")
                        Text("•")
                    } else if game.overtime {
                        Text("Overtime")
                        Text("•")
                    }
                    Text(LocalizedStringKey(game.start_date_time.getFormattedDate()))
                }
                
                PickedLabel(picked: pick?.pickedTeam == game.away_team_code)
            }
            .font(.system(size: 14, weight: .bold, design: .rounded))
            .foregroundColor(Color(UIColor.secondaryLabel))
        }
        .frame(maxWidth: .infinity)
    }
}

struct PickemSectionView: View {
    @EnvironmentObject var games: GamesData
    @EnvironmentObject var pickemsData: PickemData
    
    @State var showPickems = false
    @State var showStats = false
    @State var nrCorrects: Int?
    
    var body: some View {
        Text("Pick'em").listHeader(true)
            .padding(.leading, 35)
            .padding(.bottom, -8)
        HStack(spacing: 20) {
            
            Button {
                withAnimation(.linear(duration: 3.0)) {
                    self.showPickems = true
                }
            } label: {
                Image(systemName: "rectangle.stack").font(.system(size: 14, weight: .heavy))
                Text("PICKEM.PICK").rounded(size: 16, weight: .heavy).padding(.leading, -2)
            }
            .padding()
            .background(Color(UIColor.secondarySystemGroupedBackground))
            .cornerRadius(20)
            .overlay(RoundedRectangle(cornerRadius: 20).stroke(.gray.opacity(0.3)))
            Spacer()
            Button {
                self.showStats = true
            } label: {
                HStack(spacing: 0) {
                    Text("🏅").rounded(size: 20, weight: .heavy)
                    PointsLabel(val: nrCorrects != nil ? "\(nrCorrects!)" : "", nrDigits: 3)
                        .font(.system(size: 30, weight: .heavy, design: .rounded))
                }
            }
        }
        .padding(.horizontal, 36)
        .onAppear {
            let corrects = pickemsData.getNrCorrect(playedGames: games.getGames().filter { $0.isPlayed() })
            self.nrCorrects = corrects > 0 ? corrects : nil
        }
        .sheet(isPresented: $showPickems){
            if #available(iOS 16.0, *) {
                PickemView(isPresent: $showPickems)
                    .presentationDragIndicator(.visible)
                    .presentationDetents([.height(280)])
            } else {
                PickemView(isPresent: $showPickems)
            }
        }
        .sheet(isPresented: $showStats){
            if #available(iOS 16.0, *) {
                PickemStatsView()
                    .presentationDragIndicator(.visible)
                    .presentationDetents([.medium, .large])
            } else {
                PickemStatsView()
            }
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
            
            ScrollView {
                if #available(iOS 16.0, *) {
                } else {
                    PullToRefresh(coordinateSpaceName: "season_scrollview") {
                        Task {
                            await self.reloadData(5)
                        }
                    }
                    Spacer(minLength: 10)
                }
                WidgetPromo()
                if (!liveGames.isEmpty) {
                    GroupedView(title: "Live", cornerRadius: 20) {
                        ForEach(liveGames) { (item) in
                            NavigationLink(destination: GamesStatsView(game: item)) {
                                LiveGame(game: item)
                                    .contentShape(Rectangle())
                                    .padding(.vertical, 20)
                            }
                            .buttonStyle(ActiveButtonStyle())
                            if item != liveGames.last {
                                Divider()
                            }
                        }
                    }
                    Spacer(minLength: 30)
                }
                
                if !futureGames.isEmpty {
                    
                    GroupedView(title: "Coming") {
                        ForEach(futureGames) { (item) in
                            NavigationLink(destination: GamesStatsView(game: item)) {
                                ComingGame(game: item)
                                    .contentShape(Rectangle())
                                    .id(arc4random())
                                    .padding(.vertical, 20)
                            }
                            .buttonStyle(ActiveButtonStyle())
                            if item != futureGames.last {
                                Divider()
                            }
                        }
                    }
                    Spacer(minLength: 30)
                }
                if settings.season == Settings.currentSeason {
                    PickemSectionView()
                    Spacer(minLength: 40)
                }
                if !playedGames.isEmpty {
                    GroupedView(title: "Played") {
                        LazyVStack(spacing: 0) {
                            ForEach(playedGames) { (item) in
                                NavigationLink(destination: GamesStatsView(game: item)) {
                                    PlayedGame(game: item)
                                        .contentShape(Rectangle())
                                        .id(arc4random())
                                        .padding(.vertical, 20)
                                }
                                .buttonStyle(ActiveButtonStyle())
                                if item != playedGames.last {
                                    Divider()
                                }
                            }
                        }
                    }
                }
                Spacer(minLength: 40)
            }
            .refreshable {
                await self.reloadData(5)
            }
            .coordinateSpace(name: "season_scrollview")
            .id(settings.season) // makes sure list is recreated when rerendered. To take care of reuse cell issues
            .listStyle(InsetGroupedListStyle())
            .navigationBarTitle(Text("Matches"))
            .navigationBarItems(trailing: NavigationLink(destination: SettingsView()) {
                Label("Settings", systemImage: "gearshape")
            })
            /*.navigationBarItems(trailing: Button {
                self.teamSelectSheetVisible.toggle()
            } label: {
                Label("Team Select", systemImage: "ellipsis")
            })*/
            .background(Color(uiColor: .systemGroupedBackground))
        }
        .accentColor(Color(uiColor: .label))
        /*.sheet(isPresented: $teamSelectSheetVisible) {
            if #available(iOS 16.0, *) {
                TeamSelectView(selectedTeams: $selectedTeams, description: "Select teams to see")
                    .presentationDragIndicator(.visible)
            } else {
                TeamSelectView(selectedTeams: $selectedTeams, description: "Select teams to see")
            }
        }*/
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
                                    getLiveGame(t1: "MIF", score1: 0, t2: "TIK", score2: 1, status: "Intermission"),
                                    getLiveGame(t1: "RBK", score1: 1, t2: "MODO", score2: 3, status: "Period2"),
                                                       
                                    getPlayedGame(t1: "LIF", s1: 4, t2: "LHC", s2: 1),
                                    getPlayedGame(t1: "HV71", s1: 3, t2: "SAIK", s2: 1, overtime: true),
                                    getPlayedGame(t1: "OHK", s1: 2, t2: "RBK", s2: 1, overtime: true, date: Date().addingTimeInterval(TimeInterval(-1000_000))),
                
                                    getFutureGame(t1: "LHF", t2: "TBD", days: 1),
                                    getFutureGame(t1: "LHF", t2: "TIK", days: 2)])
        let starredTeams = StarredTeams()
        starredTeams.addTeam(teamCode: "LHF")
        starredTeams.addTeam(teamCode: "TIK")
        starredTeams.addTeam(teamCode: "RBK")
        
        UserDefaults.shared.setValue([
            "\(gamesData.data[1].game_uuid)::\(gamesData.data[1].away_team_code)",
            "\(gamesData.data[2].game_uuid)::\(gamesData.data[2].home_team_code)",
            "\(gamesData.data[6].game_uuid)::\(gamesData.data[6].home_team_code)",
        ], forKey: "picks.\(Settings.currentSeason)")
        
        let pickemData = getPickemData()
        
        return SeasonView(provider: nil)
            .environmentObject(starredTeams)
            .environmentObject(gamesData)
            .environmentObject(getTeamsData())
            .environmentObject(Settings())
            .environmentObject(pickemData)
            .environment(\.locale, .init(identifier: "sv"))
    }
}

struct PlayedCells_Previews: PreviewProvider {
    static var previews: some View {
    
        let gamesData = GamesData(data: [
                                    getLiveGame(t1: "MIF", score1: 4, t2: "TIK", score2: 2, status: "Intermission"),
                                    getLiveGame(t1: "MIF", score1: 1, t2: "TIK", score2: 3, status: nil),
                                    getLiveGame(t1: "LHF", score1: 4, t2: "FHC", score2: 2),
                                                       
                                    getPlayedGame(t1: "LHF", s1: 4, t2: "FBK", s2: 1),
                                    getPlayedGame(t1: "HV71", s1: 3, t2: "MODO", s2: 1, overtime: true),
                                    getPlayedGame(t1: "OHK", s1: 2, t2: "RBK", s2: 1, overtime: true, date: Date().addingTimeInterval(TimeInterval(-1000_000))),
                
                                    getFutureGame(t1: "LHF", t2: "TBD", days: 1),
                                    getFutureGame(t1: "LHF", t2: "TIK", days: 2)])
        let starredTeams = StarredTeams()
        starredTeams.addTeam(teamCode: "LHF")
        starredTeams.addTeam(teamCode: "TIK")
        starredTeams.addTeam(teamCode: "RBK")
        
        return VStack {
            PlayedGame(game: getPlayedGame(t1: "MODO", s1: 4, t2: "FBK", s2: 1))
            PlayedGame(game: getPlayedGame(t1: "SAIK", s1: 4, t2: "MODO", s2: 1))
        }
            .environmentObject(starredTeams)
            .environmentObject(gamesData)
            .environmentObject(getTeamsData())
            .environmentObject(Settings())
            .environmentObject(getPickemData())
            .environment(\.locale, .init(identifier: "sv"))
    }
}

