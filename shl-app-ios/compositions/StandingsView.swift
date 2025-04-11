//
//  StandingsView.swift
//  HockeyPal
//
//  Created by Pål Forsberg on 2021-01-08.
//

import SwiftUI
import WidgetKit


extension Text {
    func points() -> some View {
        return self
            .font(.system(size: 15, weight: .heavy, design: .rounded))
    }
}

struct StandingsHeader: View {
    var season: String
    var body: some View {
        HStack {
            Text("Season_param \(season)").listHeader(true)
            Spacer()
            Text("GP")
                .rounded(size: 15, weight: .bold)
                .frame(width: 34, alignment: .center)
                .foregroundColor(Color(uiColor: .secondaryLabel))
            Text("P")
                .rounded(size: 15, weight: .bold)
                .frame(width: 34, alignment: .center)
                .foregroundColor(Color(uiColor: .secondaryLabel))
            Spacer(minLength: 17)
        }
    }
}


struct PointsLabel: View {
    var val: String
    var nrDigits = 3
    var color = Color.primary
    
    var body: some View {
        let str = "\(val)"
        let nrZeros = nrDigits - str.count
        HStack(spacing: 0) {
            Text(genZeros(nrZeros)).foregroundColor(Color(UIColor.quaternaryLabel))
                .monospacedDigit()
            Text(str).foregroundColor(color)
                .monospacedDigit()
        }
    }
    
    func genZeros(_ nr: Int) -> String {
        guard nr > 0 else {
            return ""
        }
        return String((0..<nr).map{ _ in "0" })
    }
}

struct PlayoffEntryView: View {
    @EnvironmentObject var starredTeams: StarredTeams
    @EnvironmentObject var teamsData: TeamsData
    var entry: PlayoffEntry
    var mini: Bool = true
    
    var body: some View {
        VStack {
            HStack {
                TeamLogo(code: entry.team1, size: UIScreen.isMini ? 20 : 30)
                if !mini {
                    Text(teamsData.getDisplayCode(entry.team1))
                        .starred(starredTeams.isStarred(teamCode: entry.team1))
                        .scaledToFit()
                        .minimumScaleFactor(0.6)
                        .frame(width: 45, alignment: .leading)
                }
                Text("\(entry.score1)").monospacedDigit()
            }.opacity(entry.team1 == "TBD" || entry.team1 == entry.eliminated ? 0.4 : 1.0)
            HStack {
                TeamLogo(code: entry.team2, size: UIScreen.isMini ? 20 : 30)
                if !mini {
                    Text(teamsData.getDisplayCode(entry.team2))
                        .starred(starredTeams.isStarred(teamCode: entry.team2))
                        .scaledToFit()
                        .minimumScaleFactor(0.6)
                        .frame(width: 45, alignment: .leading)
                }
                Text("\(entry.score2)").monospacedDigit()
            }.opacity(entry.team2 == "TBD" || entry.team2 == entry.eliminated ? 0.4 : 1.0)
        }
        .font(.system(size: 18, weight: .heavy, design: .rounded))
        .padding(EdgeInsets(top: 15, leading: 15, bottom: 15, trailing: 15))
        .background(Color(uiColor: UIColor.secondarySystemGroupedBackground))
        .overlay(RoundedRectangle(cornerRadius: 20).strokeBorder(.gray.opacity(0.3)))
        .cornerRadius(20)

    }
}
struct PlayoffView: View {
    var playoff: Playoffs
    
    var select: (PlayoffEntry) -> Void
    
    var body: some View {
        VStack(spacing: 10) {
            if let final = playoff.final {
                Text("FINAL")
                    .font(.system(size: 30, weight: .heavy, design: .rounded))
                    .foregroundColor(Color(uiColor: .secondaryLabel))
                HStack {
                    Button(action: { self.select(final) }) {
                        PlayoffEntryView(entry: final, mini: false)
                    }
                }
                Spacer(minLength: 10)
            }
            if let semis = playoff.semi {
                Text("Semifinal").listHeader()
                HStack {
                    ForEach(semis) { semi in
                        Button(action: { self.select(semi) }) {
                            PlayoffEntryView(entry: semi, mini: false)
                        }
                    }
                }
                Spacer(minLength: 10)
            }
            if let quarters = playoff.quarter {
                Text("Quarterfinal").listHeader()
                HStack {
                    ForEach(quarters) { quart in
                        Button(action: { self.select(quart) }) {
                            PlayoffEntryView(entry: quart, mini: true)
                        }
                    }
                }
                Spacer(minLength: 10)
            }
            if let eight = playoff.eight {
                Text("Eightfinal").listHeader()
                HStack {
                    ForEach(eight) {eigh in
                        Button(action: { self.select(eigh) }) {
                            PlayoffEntryView(entry: eigh, mini: false)
                        }
                    }
                }
                Spacer(minLength: 10)
            }
            
            if let entry = playoff.demotion {
                Text("Demotion").listHeader()
                Button(action: { self.select(entry) }) {
                    PlayoffEntryView(entry: entry, mini: false)
                }
                Spacer(minLength: 10)
            }
        }
    }
}


struct PlayoffHistoryView: View {
    @EnvironmentObject var playoffs: PlayoffData
    @EnvironmentObject var games: GamesData
    
    @State var playoffGames: [Game] = []
    
    var entry: PlayoffEntry
    var currentGameId: String?
    
    var body: some View {
        HStack(spacing: 10) {
            ForEach(self.playoffGames) { g in
                if g.isPlayed() {
                    TeamLogo(code: g.getWinner())
                        .flashing(enabled: g.game_uuid == currentGameId)
                } else {
                    Circle()
                        .fill(Color(uiColor: .systemGray2))
                        .frame(width: 10, height: 10)
                        .padding(EdgeInsets(top: 0, leading: 5, bottom: 0, trailing: 5))
                        .flashing(enabled: g.game_uuid == currentGameId)
                }
            }
        }
        .fixedSize(horizontal: false, vertical: true)
        .task {
            self.playoffGames = Array(games
                .getPlayoffGamesBetween(t1: entry.team1, t2: entry.team2)
                .sorted { $0.start_date_time < $1.start_date_time }
                .prefix(entry.nr_games ?? 7))
        }
    }
}

struct PlayoffSheet: View {
    @EnvironmentObject var playoffs: PlayoffData
    @EnvironmentObject var teams: TeamsData
    @EnvironmentObject var games: GamesData
    
    var entry: PlayoffEntry
    
    @State var futureGames: [Game] = []
    
    var body: some View {
        ScrollView([]) {
            VStack(spacing: 10) {
                Spacer()
                Text(LocalizedStringKey(playoffs.getStage(entry: entry) ?? ""))
                    .font(.system(size: 26, weight: .bold, design: .rounded).smallCaps())
                Text(LocalizedStringKey("Best of \(entry.getNrGames()) • First to \(entry.getBestTo())"))
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .padding(EdgeInsets(top: -9, leading: 0, bottom: 10, trailing: 0))
                    .foregroundColor(Color(uiColor: .secondaryLabel))
                
                GroupedView(cornerRadius: 15) {
                    VStack(alignment: .leading) {
                        HStack(spacing: 10) {
                            TeamLogo(code: entry.team1)
                            Text(teams.getName(entry.team1))
                            Spacer()
                            Text("\(entry.score1)").fontWeight(.bold).monospacedDigit()
                        }
                        .padding(EdgeInsets(top: 12, leading: 20, bottom: 3, trailing: 20))
                        .opacity(entry.team1 == entry.eliminated ? 0.4 : 1.0)
                        Divider()
                            .padding(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
                        HStack(spacing: 10) {
                            TeamLogo(code: entry.team2)
                            Text(teams.getName(entry.team2))
                            Spacer()
                            Text("\(entry.score2)").fontWeight(.bold).monospacedDigit()
                        }
                        .padding(EdgeInsets(top: 3, leading: 20, bottom: 12, trailing: 20))
                        .opacity(entry.team2 == entry.eliminated ? 0.4 : 1.0)
                        
                    }
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                }
                .fixedSize(horizontal: false, vertical: true)
                .padding(.bottom, 30)
                
                
                PlayoffHistoryView(entry: entry)
                    .padding(.bottom, 30)
                
                if self.futureGames.count > 0 {
                    GroupedView(title: "Coming", cornerRadius: 15) {
                        ForEach(self.futureGames) { (item) in
                            ComingGame(game: item)
                                .padding(EdgeInsets(top: 15, leading: 0, bottom: 15, trailing: 0))
                        }
                    }
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.bottom, 30)
                }
                Spacer()
            }
        }
        .background(Color(UIColor.systemGroupedBackground)
            .edgesIgnoringSafeArea(.all))
        .ignoresSafeArea(edges: .all)
        .task {
            if entry.team1 != "TBD",
               entry.team2 != "TBD" {
                self.futureGames = games
                    .getPlayoffGamesBetween(t1: entry.team1, t2: entry.team2)
                    .filter { !$0.isPlayed() }
            }
        }
    }
}

struct TeamEntry: View {
    @EnvironmentObject var starredTeams: StarredTeams
    var code: String
    var display_code: String
    
    var body: some View {
        TeamLogo(code: code)
        Text(display_code)
            .font(.system(size: 20, weight: .heavy, design: .rounded))
            .starred(starredTeams.isStarred(teamCode: code))
    }
}

struct StandingsView: View {
    @Namespace var animation
    @EnvironmentObject var standings: StandingsData
    @EnvironmentObject var games: GamesData
    @EnvironmentObject var teams: TeamsData
    @EnvironmentObject var starredTeams: StarredTeams
    @EnvironmentObject var settings: Settings
    @EnvironmentObject var playoffs: PlayoffData

    var provider: DataProvider?
    
    @State var selectedPlayoff: PlayoffEntry?
    @State var overwriteStandings: [Standing]?
    
    @AppStorage("standing.league") var league = League.shl
    
    var body: some View {
        let standings = overwriteStandings ?? self.standings.get(for: self.league)
        
        NavigationView {
            ScrollView {
                if let po = self.playoffs.get(for: self.league) {
                    PlayoffView(playoff: po, select: self.select)
                    Spacer(minLength: 10)
                }
                HStack {
                    Text("Season_param \(settings.getFormattedSeason())").listHeader(true)
                    Spacer()
                    Text("GP").frame(width: 30, alignment: .center)
                    Text("P").frame(width: 34, alignment: .center)
                    Spacer(minLength: 17)
                }
                .font(.system(size: 15, weight: .bold, design: .rounded))
                .foregroundColor(Color(uiColor: .secondaryLabel))
                .padding(EdgeInsets(top: 0, leading: 10, bottom: -2, trailing: 10))
                GroupedView(cornerRadius: 15) {
                    ForEach(standings, id: \.team_code) { item in
                        let orig = self.getOriginal(team_code: item.team_code)
                        NavigationLink(destination: TeamView(teamCode: item.team_code, standing: item)) {
                            VStack(spacing: 0) {
                                HStack() {
                                    PointsLabel(val: "\(item.rank)", nrDigits: 2)
                                        .overlay {
                                            if let o = orig, o.rank != item.rank {
                                                HStack(spacing: 2) {
                                                    Text(o.rank - item.rank > 0 ? "▴" : "▾")
                                                        .rounded(size: 12, weight: .black) +
                                                    Text("\(abs(o.rank - item.rank))")
                                                        .rounded(size: 12, weight: .black)
                                                }
                                                .offset(x: 2, y: 14)
                                                .foregroundColor(Color(o.rank - item.rank > 0 ? UIColor.systemYellow : UIColor.systemRed))
                                            }
                                        }
                                    TeamEntry(code: item.team_code, display_code: teams.getDisplayCode(item.team_code))
                                        .id("team-\(item.team_code)")
                                    Spacer()
                                    PointsLabel(val: "\(item.gp)", nrDigits: 2)
                                        .frame(width: 30, alignment: .center)
                                    PointsLabel(val: "\(item.points)")
                                        .frame(width: 34, alignment: .center)
                                        .overlay {
                                            if let o = orig, o.points != item.points {
                                                Text("+\(item.points - o.points)")
                                                    .rounded(size: 12, weight: .black)
                                                    .foregroundColor(Color(UIColor.systemYellow))
                                                    .offset(x: 6, y: 14)
                                            }
                                        }
                                }
                                .font(.system(size: 15, weight: .heavy, design: .rounded))
                                .zIndex(starredTeams.isStarred(teamCode: item.team_code) ? 1000 : 1)
                                .padding(EdgeInsets(top: 14, leading: 10, bottom: 14, trailing: 16))
                            }
                            .contentShape(Rectangle())
                        }
                        .transition(.scale)
                        .buttonStyle(ActiveButtonStyle())
                        if item.team_code != standings.last?.team_code {
                            Divider()
                        }
                        if item.rank == 6 || item.rank == 10 || item.rank == 12 {
                            Rectangle()
                                .fill(Color(UIColor.systemGroupedBackground))
                            Divider()
                        }
                    }
                }
                Spacer(minLength: 40)
            }
            .refreshable {
                debugPrint("[STANDING] refreshable")
                await self.reloadData(5)
            }
            .id(settings.season) // makes sure list is recreated when rerendered. To take care of reuse cell issues
            .navigationBarTitle(Text(self.league == .shl ? "SHL" : "HA").rounded(size: 16))
            .background(Color(UIColor.systemGroupedBackground))
            .navigationBarItems(trailing: NavigationLink(destination: SettingsView()) {
                Label("Settings", systemImage: "gearshape")
            })
            .navigationBarItems(leading: Button {
                self.league = self.league == .shl ? .ha : .shl
            } label: {
                Text(self.league == .ha ? "SHL" : "HA")
                    .rounded(size: 16, weight: .semibold)
            }.frame(height: 44))
            
            .overlay(alignment: .bottomTrailing) {
                HStack {
                    Spacer()
                    Button {
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "arrow.up.arrow.down").font(.system(size: 10, weight: .bold, design: .rounded))
                            Text("Live Rank")
                                .rounded(size: 14, weight: .heavy)
                        }
                    }
                    .simultaneousGesture(DragGesture(minimumDistance: 0, coordinateSpace: .local).onChanged({_ in
                        guard self.overwriteStandings == nil else { return }
                        UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
                        withAnimation(.spring) {
                            self.overwriteStandings = self.standings
                                .addLiveGames(league: self.league, live_games: self.games.live_games.filter { $0.isSeasonGame() })
                        }
                    }).onEnded({_ in
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        withAnimation(.spring) {
                            self.overwriteStandings = nil
                        }
                    }))
                    .padding(EdgeInsets(top: 15, leading: 15, bottom: 15, trailing: 15))
                    .accentColor(Color(uiColor: .label))
                    .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
                    .overlay { RoundedRectangle(cornerRadius: 20, style: .continuous).stroke(.gray.opacity(0.3)) }
                    .shadow(color: Color(uiColor: .black).opacity(0.2), radius: 4, x: 0, y: 0)
                }
                .opacity(self.games.live_games
                    .filter { $0.league == self.league }
                    .filter { $0.isSeasonGame() }
                    .count > 0 ? 1 : 0)
                .padding(.trailing, 30)
                .padding(.bottom, 20)
            }
        }
        .task(id: settings.season) {
            debugPrint("[STANDINGS] task")
            await self.reloadData(60)
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
            debugPrint("[STANDINGS] applicationWillEnterForeground")
            Task {
                await self.reloadData(15 * 60)
            }
        }
        .sheet(item: $selectedPlayoff, onDismiss: {
            self.selectedPlayoff = nil
        }) { p in
            PlayoffSheet(entry: p)
                .presentationDetents([.medium, .large])
        }
    }
    
    func reloadData(_ maxAge: TimeInterval = 10) async {
        async let standings = provider?.getStandings(season: settings.season, maxAge: maxAge)
        async let playoffs = provider?.getPlayoffs(season: settings.season, maxAge: maxAge)
        
        let (result_standings, result_playoffs) = await (standings, playoffs)
        
        if let standings = result_standings?.entries {
            withAnimation {
                self.standings.set(data: standings)
            }
        }
        if result_standings?.type == .api {
            WidgetCenter.shared.reloadAllTimelines()
            debugPrint("[STANDINGS] reload widgets")
        }
        
        withAnimation {
            self.playoffs.set(data: result_playoffs?.entries)
        }
    }
    
    func select(playoff: PlayoffEntry) {
        guard self.selectedPlayoff == nil else {
            // guard against race condition of closing and opening sheet real fast, causing selectedPlayer to be overwritten incorrectly
            print("Selected Playoff not nil \(self.selectedPlayoff?.team1 ?? "")")
            return
        }
        self.selectedPlayoff = playoff
    }
    
    func getOriginal(team_code: String) -> Standing? {
        guard self.overwriteStandings != nil else {
            return nil
        }
        return self.standings.get(for: self.league)
            .first { s in s.team_code == team_code }
    }
}


struct StandingsViewWithoutPlayoff_Previews: PreviewProvider {
    static var previews: some View {
        let starredTeams = StarredTeams()
        starredTeams.addTeam(teamCode: "SAIK")
        
        let playoffs = PlayoffData()
        playoffs.set(data: nil)
        return StandingsView(provider: nil)
            .environmentObject(getTeamsData())
            .environmentObject(starredTeams)
            .environmentObject(getGamesData())
            .environmentObject(getStandingsData())
            .environmentObject(Settings())
            .environmentObject(playoffs)
            .environment(\.locale, .init(identifier: "sv"))
    }
}


struct StandingsView_Previews: PreviewProvider {
    static var previews: some View {
        let starredTeams = StarredTeams()
        starredTeams.addTeam(teamCode: "SAIK")

        let playoffs = PlayoffData()
        playoffs.set(data: getPlayoffs())
        return StandingsView(provider: nil)
            .environmentObject(TeamsData())
            .environmentObject(starredTeams)
            .environmentObject(getStandingsData())
            .environmentObject(getGamesData())
            .environmentObject(Settings())
            .environmentObject(playoffs)
            .environment(\.locale, .init(identifier: "sv"))
    }
}

struct PlayoffView_Previews: PreviewProvider {
    static var previews: some View {
        return ScrollView() {
            PlayoffView(playoff: getPlayoffs().SHL!, select: { e in })
        }.background(Color(uiColor: .systemGroupedBackground))
    }
}

struct PlayoffSheet_Previews: PreviewProvider {
    static var previews: some View {
        let data = PlayoffData()
        data.set(data: getPlayoffs())
        
        let entry = getPlayoffs().SHL!.quarter![0]
        let gamesData = GamesData(data: [])

        gamesData.set(data: [
            getPlayoffGame(t1: entry.team1, s1: 1, t2: entry.team2, s2: 2),
            getPlayoffGame(t1: entry.team1, s1: 3, t2: entry.team2, s2: 2),
            getPlayoffGame(t1: entry.team1, s1: 3, t2: entry.team2, s2: 2),
            getPlayoffGame(t1: entry.team1, s1: 1, t2: entry.team2, s2: 2),
            getPlayoffGame(t1: entry.team1, s1: 0, t2: entry.team2, s2: 0, status: "Coming"),
        ])
        return PlayoffSheet(entry: getPlayoffs().SHL!.quarter![0])
                .environmentObject(data)
                .environmentObject(StarredTeams())
                .environmentObject(getTeamsData())
                .environmentObject(gamesData)
                .background(Color(uiColor: .systemGroupedBackground))
                .environment(\.locale, .init(identifier: "sv"))
    }
}
