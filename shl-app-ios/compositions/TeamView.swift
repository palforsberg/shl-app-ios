//
//  TeamView.swift
//  HockeyPal
//
//  Created by Pål Forsberg on 2021-01-14.
//

import SwiftUI
import Charts

struct StatsRowSingle: View {
    var left: String
    var right: String
    
    var body: some View {
        HStack() {
            Text(LocalizedStringKey(left))
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .frame(maxWidth: .infinity, alignment: .leading)
            Spacer()
            Text(right)
                .font(.system(size: 20, weight: .heavy, design: .rounded))
                .frame(alignment: .trailing)
                .monospacedDigit()
        }.padding(EdgeInsets(top: 3, leading: 0, bottom: 3, trailing: 0))
    }
}

struct TopPlayerEntry: View {
    var player: Player
    var action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .center, spacing: 10) {
                HStack(alignment: .center) {
                    PlayerImage(player: "\(player.id)", size: 50)
                    VStack(alignment: .center) {
                        Text("\(player.first_name)").minimumScaleFactor(0.6).scaledToFit()
                        Text("\(player.family_name)").minimumScaleFactor(0.6).scaledToFit()
                    }.font(.system(size: 16, weight: .bold, design: .rounded))
                }
                HStack(spacing: 10) {
                    Text("#\(player.jersey)").fontWeight(.heavy)
                    Text("\(player.position)")
                    if player.position != "GK" {
                        Text("\(player.getPoints()) P")
                    } else {
                        Text(String(format: "%.0f %%", player.getSavesPercentage()))
                    }
                    
                }.font(.system(size: 16, weight: .medium, design: .rounded))
                    .frame(maxWidth: .infinity)
                    .foregroundColor(Color(uiColor: .secondaryLabel))
                
            }
            .padding(EdgeInsets(top: 15, leading: 5, bottom: 15, trailing: 5))
        }
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .cornerRadius(20)
        .overlay(RoundedRectangle(cornerRadius: 20).strokeBorder(.gray.opacity(0.3)))
        .buttonStyle(ActiveButtonStyle())
    }
}

struct PlayerEntry: View {
    var player: Player

    var body: some View {
        HStack(spacing: 16) {
            PlayerImage(player: "\(player.id)", size: 36)
            VStack {
                HStack {
                    Text("\(player.first_name) \(player.family_name)")
                    Spacer()
                    if player.position != "GK" {
                        Text("\(player.getPoints()) P")
                            .fontWeight(.medium)
                    } else {
                        Text(String(format: "%.0f %%", player.getSavesPercentage()))
                            .fontWeight(.medium)
                    }
                }.padding(.bottom, -6)
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                
                HStack {
                    Text("#\(player.jersey)").fontWeight(.heavy)
                    Text("\(player.position)")
                
                    Spacer()
                }.font(.system(size: 16, weight: .medium, design: .rounded))
                    .foregroundColor(Color(uiColor: .secondaryLabel))
            }
        }
        .padding(EdgeInsets(top: 20, leading: 30, bottom: 20, trailing: 30))
    }
}

struct VStat: View {
    var stat: String
    var nr: String
    var statSize: CGFloat = 24
    var body: some View {
        VStack(spacing: 3) {
            Text(LocalizedStringKey(stat))
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .scaledToFit()
                .minimumScaleFactor(0.6)
            Text(nr)
                .font(.system(size: statSize, weight: .heavy, design: .rounded))
                .monospacedDigit()
                .scaledToFit()
                .minimumScaleFactor(0.6)
                .contentTransition(.numericText())
        }
    }
}
struct PlayerStatsSheet: View {
    @EnvironmentObject var settings: Settings
    
    var initPlayer: Player
    var provider: DataProvider?
    
    @Namespace var ns
    
    @State var player: Player
    @State var summary: PlayerSummary?
    @State var fetchedPlayerInfo: [Player]?
    
    init(player: Player, provider: DataProvider? = nil) {
        self.initPlayer = player
        self.player = player
        self.provider = provider
    }
    
    var body: some View {
        ScrollView([]) {
            VStack {
                Spacer(minLength: 20)
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack {
                        Spacer(minLength: 20)
                        ForEach(values: fetchedPlayerInfo ?? []) { p in
                            Button {
                                withAnimation(.spring(duration: 0.5, bounce: 0.4)) {
                                    self.player = p
                                }
                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            } label: {
                                TeamLogo(code: p.team_code, size: 20)
                                Text(p.getSeason().getString())
                                    .foregroundColor(Color(uiColor: .label))
                            }
                            .padding(.vertical, 8)
                            .padding(.horizontal, 10)
                            .background {
                                if player.team_season_id == p.team_season_id {
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .fill(Color(uiColor: .tertiarySystemFill))
                                        .matchedGeometryEffect(id: "selected", in: ns)
                                }
                            }
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .disabled(player.team_season_id == p.team_season_id)
                            .opacity(player.team_season_id == p.team_season_id ? 1 : 0.5)
                        }
                        Spacer(minLength: 20)
                    }
                    
                    .frame(minWidth: UIScreen.main.bounds.width)
                }
                .contentMargins(.horizontal, 0, for: .scrollContent)
                .defaultScrollAnchor(.trailing)
                .padding(.top, 20)
                .padding(.bottom, 20)
                
                HStack(alignment: .center, spacing: 20) {
                    PlayerImage(player: "\(player.id)", size: 90)
                    VStack(alignment: .leading, spacing: 5) {
                        Text("\(player.first_name) \(player.family_name)")
                            .minimumScaleFactor(0.6).scaledToFit()
                            .font(.system(size: 25, weight: .bold, design: .rounded))
                        HStack(spacing: 10) {
                            TeamLogo(code: player.team_code, size: 24)
                            Text("#\(player.jersey)")
                                .font(.system(size: 20, weight: .bold, design: .rounded))
                            Text("\(player.position)")
                                .font(.system(size: 20, weight: .semibold, design: .rounded))
                        }
                        
                        HStack(spacing: 10) {
                            Text("\(summary?.getFlag() ?? "-")")
                            Text("\(summary?.weight.map { "\($0)" } ?? "- ")kg")
                            Text("\(summary?.height.map { "\($0)" } ?? "- ")cm")
                            Text("\(summary?.getAge().map { "\($0)" } ?? "- ")år")
                        }
                        .font(.system(size: 16, weight: .semibold, design: .rounded)
                            .lowercaseSmallCaps())
                        .frame(minHeight: 18)
                        .padding(.top, 2)
                        
                    }.font(.system(size: 25, weight: .bold, design: .rounded))
                }
                .fixedSize(horizontal: false, vertical: true)
                .padding(.bottom, 20)
                
                if !isAllowed() {
                        Image(systemName: "heart")
                            .font(.system(size: 30))
                            .foregroundStyle(Color(uiColor: .secondaryLabel))
                            .padding(.bottom, 10)
                        Text("Bli supporter för att få tillgång till statistik från tidigare säsonger")
                            .rounded(size: 14, weight: .bold)
                            .foregroundStyle(Color(uiColor: .secondaryLabel))
                            .multilineTextAlignment(.center)
                } else  if player.position == "GK" {
                    GroupedView {
                        HStack {
                            Spacer()
                            VStat(stat: "Saves %", nr: String(format: "%.0f%%", player.getSavesPercentage()))
                            Spacer()
                            VStat(stat: "Goals Against", nr: "\(player.ga ?? 0)")
                            Spacer()
                            VStat(stat: "Shots Against", nr: "\(player.soga ?? 0)")
                            Spacer()
                        }.padding(EdgeInsets(top: 20, leading: 0, bottom: 20, trailing: 0))
                    }.fixedSize(horizontal: false, vertical: true)
                        .padding(.bottom, 10)
                    
                    GroupedView {
                        HStack {
                            Spacer()
                            VStat(stat: "Home", nr: "\(player.gp)")
                            Spacer()
                            VStat(stat: "Saves", nr: "\(player.svs ?? 0)")
                            Spacer()
                        }.padding(EdgeInsets(top: 20, leading: 0, bottom: 20, trailing: 0))
                    }.fixedSize(horizontal: false, vertical: true)
                        .padding(.bottom, 10)
                } else {
                    GroupedView {
                        HStack {
                            Spacer()
                            VStat(stat: "Points", nr: "\(player.getPoints())", statSize: 26)
                            Spacer()
                            VStat(stat: "Goal", nr: "\(player.g ?? 0)", statSize: 26)
                            Spacer()
                            VStat(stat: "Assist", nr: "\(player.a ?? 0)", statSize: 26)
                            Spacer()
                        }.padding(EdgeInsets(top: 20, leading: 0, bottom: 20, trailing: 0))
                    }
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.bottom, 10)
                    
                    GroupedView {
                        HStack {
                            Spacer()
                            VStat(stat: "Home", nr: "\(player.gp)")
                            Spacer()
                            VStat(stat: "+/-", nr: player.getPlusMinus())
                            Spacer()
                            VStat(stat: "Points/Game", nr: String(format: "%.2f", player.getPointsPerGame()))
                            Spacer()
                        }.padding(EdgeInsets(top: 20, leading: 0, bottom: 20, trailing: 0))
                    }.fixedSize(horizontal: false, vertical: true)
                        .padding(.bottom, 10)
                    
                    GroupedView {
                        HStack {
                            Spacer()
                            VStat(stat: "Shots", nr: "\(player.sog ?? 0)")
                            Spacer()
                            VStat(stat: "Goals/Shot", nr: String(format: "%.0f%%", player.getGoalsPerShotPercentage()))
                            Spacer()
                        }.padding(EdgeInsets(top: 20, leading: 0, bottom: 20, trailing: 0))
                    }.fixedSize(horizontal: false, vertical: true)
                        .padding(.bottom, 10)
                    
                    GroupedView {
                        HStack {
                            Spacer()
                            VStat(stat: "Time/Game", nr: player.getToiPerGameFormatted())
                            Spacer()
                            VStat(stat: "Time On Ice", nr: player.getToiFormatted())
                            Spacer()
                            VStat(stat: "Penalty Time", nr: String(format: "%02d:00", player.pim ?? 0))
                            Spacer()
                        }.padding(EdgeInsets(top: 20, leading: 0, bottom: 20, trailing: 0))
                    }.fixedSize(horizontal: false, vertical: true)
                        .padding(.bottom, 10)
                }
                Spacer(minLength: 30)
            }
        }
        .background(Color(UIColor.systemGroupedBackground)
            .edgesIgnoringSafeArea(.all))
        .ignoresSafeArea(edges: .all)
        .task {
            await self.fetchPlayerData()
        }
    }
    
    func fetchPlayerData() async {
        let (sum, pi) = await (
            provider?.getPlayerSummary(player: player.id),
            provider?.getPlayer(player: player.id)?.sorted { $0.team_season_id < $1.team_season_id }
        )
        self.summary = sum
        self.fetchedPlayerInfo = pi
        
        withAnimation(.easeOut) {
            
        }
    }
    
    func isAllowed() -> Bool {
        if !settings.supporter, let actualSeason = Season(rawValue: "Season\(Settings.currentSeason)") {
            return player.getSeason() == actualSeason
        }
        return true
    }
}

struct GoldView: View {
    var golds: [String]?
    @State var expanded = false
    
    var body: some View {
        if golds?.count ?? 0 > 0 {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: -5) {
                    ForEach(golds?.reversed() ?? [], id: \.self) { game in
                        HStack(spacing: 0) {
                            Text("🥇").font(.system(size: 20))
                            if expanded {
                                Text(game)
                                    .rounded(size: 12, weight: .bold)
                                    .foregroundColor(Color(uiColor: .systemYellow))
                                    .transition(.opacity)
                            }
                        }
                        .frame(width: expanded ? 70 : nil)
                    }
                }
                .onTapGesture {
                    withAnimation(.spring()) {
                        self.expanded.toggle()
                    }
                }
                .frame(minWidth: UIScreen.main.bounds.width)
            }
        }
    }
}

struct TeamView: View {
    @EnvironmentObject var starredTeams: StarredTeams
    @EnvironmentObject var teams: TeamsData
    @EnvironmentObject var games: GamesData
    @EnvironmentObject var settings: Settings

    let teamCode: String
    let standing: Standing
    
    var provider: DataProvider? = DataProvider()
    
    @State var goalKeepers: [Player]?
    @State var topPlayers: [Player]?
    @State var allPlayers: [Player]?
    @State var showingAllPlayers = false
    @State var selectedPlayer: Player?
    @State var showingAllPlayedGames = false
    
    var body: some View {
        let team = self.teams.getTeam(teamCode)
        let starred = starredTeams.isStarred(teamCode: teamCode)
        let liveGames = games.getLiveGames(filter: .teams([teamCode]))
        let futureGames = games.getFutureGames(filter: .teams([teamCode]), starred: starredTeams.starredTeams, includeToday: true)
        let playedGames = games.getPlayedGames(filter: .teams([teamCode]), starred: starredTeams.starredTeams, ).prefix(showingAllPlayedGames ? 1000 : 5)
        ScrollView {
            VStack(alignment: .center, spacing: 0) {
                VStack(spacing: 10) {
                    VStack(spacing: 0) {
                        Text("\(standing.league.rawValue) • \(settings.getFormattedSeason())")
                        if let founded = team?.founded {
                            Text("Grundat \(founded)")
                                .foregroundColor(Color(UIColor.secondaryLabel))
                        }
                        GoldView(golds: team?.golds)
                            .padding(.top, 4)
                    }
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundColor(Color(UIColor.secondaryLabel))
                    VStack(spacing: 2) {
                        TeamLogo(code: teamCode, size: 70)
                    
                        Text(team?.name ?? teamCode)
                            .rounded(size: 24, weight: .heavy)
                            .starred(starred)
                    }
                    Spacer(minLength: 6)
                    StarButton(starred: starred) {
                        if (starred) {
                            starredTeams.removeTeam(teamCode: teamCode)
                        } else {
                            starredTeams.addTeam(teamCode: teamCode)
                        }
                    }
                }
                Spacer(minLength: 20)
                Group {
                    GroupedView(title: "Season_param \(settings.getFormattedSeason())") {
                        VStack {
                            StatsRowSingle(left: "Rank", right: "#\(standing.rank)")
                            StatsRowSingle(left: "Points", right: "\(standing.points)")
                            StatsRowSingle(left: "Goal Diff", right: "\(standing.diff)")
                            StatsRowSingle(left: "Games Played", right: "\(standing.gp)")
                            StatsRowSingle(left: "Points/Game", right: standing.getPointsPerGame())
                            if playedGames.count > 0 {
                                HStack() {
                                    Text(LocalizedStringKey("Form"))
                                        .font(.system(size: 20, weight: .bold, design: .rounded))
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                    Spacer()
                                    FormGraph(teamCode: teamCode)
                                }.padding(EdgeInsets(top: 3, leading: 0, bottom: 3, trailing: 0))
                            }
                        }.padding(EdgeInsets(top: 16, leading: 24, bottom: 16, trailing: 24))
                    }
                    Spacer(minLength: 30)
                }
                if let players = self.topPlayers {
                    Group {
                        Text("Players").listHeader(true).padding(.leading, 14)
                            .padding(.bottom, 6)
                        Group {
                            HStack(spacing: 20) {
                                if let p = players[safe: 0] {
                                    TopPlayerEntry(player: p, action: { self.select(player: p) })
                                }
                                if let p = players[safe: 1] {
                                    TopPlayerEntry(player: p, action: { self.select(player: p) })
                                }
                            }
                            Spacer(minLength: 20)
                            HStack(spacing: 20) {
                                if let p = players[safe: 2] {
                                    TopPlayerEntry(player: p, action: { self.select(player: p) })
                                }
                                if let p = players[safe: 3] {
                                    TopPlayerEntry(player: p, action: { self.select(player: p) })
                                }
                            }
                        }.padding(EdgeInsets(top: 0, leading: 15, bottom: 0, trailing: 15))
                    }
                }
                if let allPlayers = self.allPlayers {
                    Spacer(minLength: 25)
                    HStack {
                        Button(self.showingAllPlayers ? "SHOW LESS" : "SHOW ALL") {
                            withAnimation {
                                self.showingAllPlayers.toggle()
                            }
                        }
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .tint(Color(uiColor: .secondaryLabel))
                    }
                    

                    if self.showingAllPlayers {
                        Spacer(minLength: 10)
                        ForEach(allPlayers, id: \.id) { p in
                            Button(action: { self.select(player: p) }) {
                                VStack(spacing: 0) {
                                        PlayerEntry(player: p)
                                    if p.id != allPlayers.last?.id {
                                        Divider()
                                            .padding(EdgeInsets(top: 0, leading: 30, bottom: 0, trailing: 30))
                                    }
                                }.contentShape(Rectangle()) // Make sure whole row is clickable
                            }.buttonStyle(ActiveButtonStyle())
                        }
                    }
                    Spacer(minLength: 20)
                }
                if (!liveGames.isEmpty) {
                    GroupedView(title: "Live", cornerRadius: 15) {
                        ForEach(liveGames) { (item) in
                            NavigationLink(destination: GamesStatsView(game: item)) {
                                LiveGame(game: item)
                                    .padding(.vertical, 20)
                                    .contentShape(Rectangle())
                            }.buttonStyle(ActiveButtonStyle())
                            if item != liveGames.last {
                                Divider()
                            }
                        }
                    }
                    Spacer(minLength: 30)
                }
                if (!futureGames.isEmpty) {
                    GroupedView(title: "Coming", cornerRadius: 15 ) {
                        ForEach(futureGames) { (item) in
                            NavigationLink(destination: GamesStatsView(game: item)) {
                                ComingGame(game: item)
                                    .padding(.vertical, 20)
                                    .contentShape(Rectangle())
                            }.buttonStyle(ActiveButtonStyle())
                            if item != futureGames.last {
                                Divider()
                            }
                        }
                    }
                    Spacer(minLength: 30)
                }
                if !playedGames.isEmpty {
                    GroupedView(title: "Played_param \(settings.getFormattedPrevSeason())", cornerRadius: 15 ) {
                        ForEach(playedGames) { (item) in
                            NavigationLink(destination: GamesStatsView(game: item)) {
                                PlayedGame(game: item)
                                    .padding(.vertical, 20)
                                    .contentShape(Rectangle())
                            }.buttonStyle(ActiveButtonStyle())
                            if item != playedGames.last {
                                Divider()
                            }
                        }
                    }
                    Spacer(minLength: 20)
                    HStack {
                        Button(self.showingAllPlayedGames ? "SHOW LESS" : "SHOW ALL") {
                            withAnimation {
                                self.showingAllPlayedGames.toggle()
                            }
                        }
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .tint(Color(uiColor: .secondaryLabel))
                    }
                    Spacer(minLength: 40)
                }
            }
            .background(Color(UIColor.systemGroupedBackground))
        }.background(Color(UIColor.systemGroupedBackground))
        .navigationBarTitle("", displayMode: .inline)
        .sheet(item: $selectedPlayer, onDismiss: {
            self.selectedPlayer = nil
        }) { p in
            PlayerStatsSheet(player: p, provider: provider)
                .presentationDetents([.medium, .large])
        }
        .task { // runs before view appears
            await self.reloadPlayers()
        }
    }
    
    func select(player: Player) {
        guard self.selectedPlayer == nil else {
            // guard against race condition of closing and opening sheet real fast, causing selectedPlayer to be overwritten incorrectly
            print("Selected Player not nil \(self.selectedPlayer?.first_name ?? "")")
            return
        }
        self.selectedPlayer = player
    }
    
    func reloadPlayers() async {
        var players = await self.provider?.getPlayers(for: settings.season, code: self.teamCode);
        if players == nil || players?.count == 0 {
            players = await self.provider?.getPlayers(for: settings.getPrevSeason(), code: self.teamCode);
        }
        guard let players = players else {
            return
        }

        let gks = players.getTopGoalKeepers()
        self.topPlayers = Array(players.getTopPlayers().prefix(3))
        
        if gks.count > 0 {
            self.topPlayers?.insert(gks[0], at: 0)
        }
        
        self.allPlayers = players
            .filter({p in p.hasPlayed()})
            .filter({ p in !(self.topPlayers?.contains(where: { a in a.id == p.id }) ?? true) })
            .sorted(by: { p1, p2 in p1.getScore() >= p2.getScore() })
    }
}

struct StarButton: View {
    var starred: Bool
    var action: () -> Void
    var body: some View {
        Button(action: action, label: {
            Image(systemName: starred ? "star.fill" : "star")
                .foregroundColor(Color(UIColor.systemYellow))
            Text("Favourite").fontWeight(.semibold)
                .font(.system(size: 18, design: .rounded))
        })
        .padding(EdgeInsets(top: 9, leading: 16, bottom: 10, trailing: 20 ))
        .background(Color(UIColor.systemGray5))
        .overlay(RoundedRectangle(cornerRadius: 24, style: .continuous)
            .strokeBorder(.gray.opacity(0.3)))
        .cornerRadius(24)
        .buttonStyle(PlainButtonStyle())
    }
}

struct TeamView_Previews: PreviewProvider {
    static var previews: some View {
        let teams = getTeamsData()
        let starred = StarredTeams()
        starred.addTeam(teamCode: "LHF")
        return Group {
            TeamView(teamCode: "LHF", standing: getStanding("LHF", rank: 1))
                .environmentObject(teams)
                .environmentObject(starred)
                .environmentObject(GamesData(data: [getLiveGame(t1: "LHF", score1: 13, t2: "FHC", score2: 2),
                                                    getLiveGame(t1: "LHF", score1: 13, t2: "FHC", score2: 2),
                                                    getPlayedGame(),
                                                    getPlayedGame(t1: "LHF", s1: 2, t2: "TIK", s2: 3, overtime: false),
                                                    getPlayedGame(t1: "LHF", s1: 3, t2: "TIK", s2: 2, overtime: true),
                                                    getPlayedGame(t1: "LHF", s1: 2, t2: "TIK", s2: 3, overtime: true),
                                                    getPlayedGame(t1: "LHF", s1: 2, t2: "TIK", s2: 3, overtime: false),
                                                    getPlayedGame(),
                                                    getPlayedGame(),
                                                    getPlayedGame(),
                                                    getPlayedGame(t1: "LHF", s1: 2, t2: "TIK", s2: 3, overtime: false),
                                                    getPlayedGame(t1: "LHF", s1: 3, t2: "TIK", s2: 2, overtime: true),
                                                    getPlayedGame(t1: "LHF", s1: 2, t2: "TIK", s2: 3, overtime: true),
                                                    getPlayedGame(t1: "LHF", s1: 2, t2: "TIK", s2: 3, overtime: false),
                                                    getPlayedGame(),
                                                    getPlayedGame(),
                                                    getPlayedGame(t1: "LHF", s1: 2, t2: "TIK", s2: 4, overtime: true),
                                                    getFutureGame(), getFutureGame()]))
                .environmentObject(Settings())
                .environmentObject(getPickemData())
                .environment(\.locale, .init(identifier: "sv"))
        }
    }
}

struct PlayerSheet_Previews: PreviewProvider {
    static var previews: some View {

        return PlayerStatsSheet(
            player: getPlayerStats(id: 2922, g: 2, a: 3, pim: 41),
            provider: DataProvider()
        )
                .environmentObject(Settings())
                .environmentObject(getPickemData())
                .environment(\.locale, .init(identifier: "sv"))
                .frame(height: 500, alignment: .top)
                .clipped()
    }
}

