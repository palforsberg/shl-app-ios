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
    var player: PlayerStats
    var action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .center, spacing: 10) {
                HStack(alignment: .center) {
                    PlayerImage(player: player.player, size: 50)
                    VStack(alignment: .center) {
                        Text("\(player.firstName)").minimumScaleFactor(0.6).scaledToFit()
                        Text("\(player.familyName)").minimumScaleFactor(0.6).scaledToFit()
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
        .buttonStyle(ActiveButtonStyle())
    }
}
struct PlayerEntry: View {
    var player: PlayerStats

    var body: some View {
        HStack(spacing: 16) {
            PlayerImage(player: player.player, size: 36)
            VStack {
                HStack {
                    Text("\(player.firstName) \(player.familyName)")
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

struct PlusMinusEntry: Identifiable  {
    var id: Int {
        get {
            i
        }
    }
    
    var i: Int
    var d: Int
}

/*
@available(iOS 16.0, *)
struct PlayerPlusMinusChart: View {
    @State var selectedPlusMins: PlusMinusEntry?
    @State var selectedPoint: CGPoint?
    
    var data: [PlusMinusEntry]
    
    var body: some View {
        Chart(data) { plusMinus in
            LineMark(
                x: .value("Game", plusMinus.i),
                y: .value("+/-", plusMinus.d))
            .foregroundStyle((plusMinus.d < 0 ? .red : .orange))
                .lineStyle(StrokeStyle(lineWidth: 5, lineCap: .round))
                .interpolationMethod(.catmullRom)
        }
        .chartOverlay { proxy in
            GeometryReader { geometry in
                if let p = self.selectedPoint {
                    Text("\(self.selectedPlusMins?.d ?? 0)")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .offset(x: p.x - 7)
                    Circle()
                        .foregroundColor(.orange)
                        .offset(x: p.x - 7, y: p.y + 14)
                        .frame(width: 14, alignment: .center)
                }
                
                Rectangle().fill(.clear).contentShape(Rectangle())
                    .gesture(
                        DragGesture(minimumDistance: 30, coordinateSpace: .local)
                            .onChanged { value in
                                // Convert the gesture location to the coordiante space of the plot area.
                                let origin = geometry[proxy.plotAreaFrame].origin
                                let location = CGPoint(
                                    x: value.location.x - origin.x,
                                    y: value.location.y - origin.y
                                )
                                let dataPoint = proxy.value(at: location, as: (Int, Int).self)!
                                self.selectedPlusMins = self.data[safe: dataPoint.0]
                                
                                if let sp = self.selectedPlusMins {
                                    self.selectedPoint = proxy.position(for: (x: dataPoint.0, y: sp.d))
                                }
                            }.onEnded({ val in
                                self.selectedPoint = nil
                                self.selectedPlusMins = nil
                            })
                    )
            }
        }
        .chartXAxisLabel("Games", alignment: .center)
        .chartYAxisLabel("+/-", alignment: .leading)
        .chartXAxis {
            AxisMarks(values: .automatic(minimumStride: 10)) { _ in
            }
        }
        .chartYAxis {
            AxisMarks(preset: .automatic, position: .automatic)
        }
    }
}
 */
struct PlayerStatsSheet: View {
    @EnvironmentObject var settings: Settings
    
    var player: PlayerStats
    var body: some View {
        ScrollView([]) {
            LazyVStack {
                Spacer(minLength: 30)
                HStack(alignment: .center, spacing: 20) {
                    PlayerImage(player: player.player, size: 90)
                    VStack(alignment: .leading) {
                        Text("\(player.firstName) \(player.familyName)")
                            .minimumScaleFactor(0.6).scaledToFit()
                            .font(.system(size: 25, weight: .bold, design: .rounded))
                        Text("#\(player.jersey) ")
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                        + Text("\(player.position)").fontWeight(.medium)
                            .font(.system(size: 20, weight: .semibold, design: .rounded))
                        
                    }.font(.system(size: 25, weight: .bold, design: .rounded))
                }
                .fixedSize(horizontal: false, vertical: true)
                .padding(.bottom, 20)
                if player.position == "GK" {
                    GroupedView {
                        VStack {
                            StatsRowSingle(left: "Saves/Shot", right: String(format: "%.0f%%", player.getSavesPercentage()))
                            StatsRowSingle(left: "Saves", right: "\(player.tot_svs ?? 0)")
                            StatsRowSingle(left: "Shots Against", right: "\(player.tot_soga ?? 0)")
                            StatsRowSingle(left: "Goals Against", right: "\(player.tot_ga ?? 0)")
                            StatsRowSingle(left: "Played Games", right: "\(player.gp ?? 0)")
                            StatsRowSingle(left: "Penalty Time", right: String(format: "%02d:00", player.pim ?? 0))
                        }.padding(EdgeInsets(top: 14, leading: 24, bottom: 14, trailing: 24))
                    }.fixedSize(horizontal: false, vertical: true)
                } else {
                    GroupedView {
                        VStack {
                            StatsRowSingle(left: "Points", right: "\(player.getPoints())")
                            StatsRowSingle(left: "Goal", right: "\(player.g ?? 0)")
                            StatsRowSingle(left: "Assist", right: "\(player.a ?? 0)")
                            StatsRowSingle(left: "Shots", right: "\(player.sog ?? 0)")
                            StatsRowSingle(left: "Goals/Shot", right: String(format: "%.0f%%", player.getGoalsPerShotPercentage()))
                        }.padding(EdgeInsets(top: 14, leading: 24, bottom: 14, trailing: 24))
                    }.fixedSize(horizontal: false, vertical: true)
                        .padding(.bottom, 10)
                    /*if #available(iOS 16.0, *), false == true {
                        PlayerPlusMinusChart(data: player.getPlusMinusEntries())
                            .frame(height: 120)
                            .padding(EdgeInsets(top: 10, leading: 30, bottom: 20, trailing: 30))
                    }*/
                    GroupedView {
                        VStack {
                            StatsRowSingle(left: "Played Games", right: "\(player.gp ?? 0)")
                            StatsRowSingle(left: "Time On Ice", right: player.getToiFormatted())
                            StatsRowSingle(left: "Time/Game", right: player.getToiPerGameFormatted())
                            StatsRowSingle(left: "Penalty Time", right: String(format: "%02d:00", player.pim ?? 0))
                            
                        }.padding(EdgeInsets(top: 14, leading: 24, bottom: 14, trailing: 24))
                    }.fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 30)
            }
        }
        .background(Color(UIColor.systemGroupedBackground)
            .edgesIgnoringSafeArea(.all))
        .ignoresSafeArea(edges: .all)
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
    
    @State var goalKeepers: [PlayerStats]?
    @State var topPlayers: [PlayerStats]?
    @State var allPlayers: [PlayerStats]?
    @State var showingAllPlayers = false
    @State var selectedPlayer: PlayerStats?
    
    var body: some View {
        let _team = self.teams.getTeam(teamCode)
        let starred = starredTeams.isStarred(teamCode: teamCode)
        let liveGames = games.getLiveGames(teamCodes: [teamCode])
        let futureGames = games.getFutureGames(teamCodes: [teamCode])
        let playedGames = games.getPlayedGames(teamCodes: [teamCode])
        ScrollView {
            VStack(alignment: .center, spacing: 0) {
                VStack(spacing: 10) {
                    Group {
                        Spacer(minLength: 5)
                        Text("Swedish Hockey League")
                            .font(.system(size: 15, weight: .bold, design: .rounded))
                            .foregroundColor(Color(UIColor.secondaryLabel))
                        Spacer(minLength: 0)
                    }
                    TeamLogo(code: teamCode, size: 50)
                    Text(_team?.name ?? teamCode)
                        .font(.system(size: 32, design: .rounded))
                        .fontWeight(.semibold)
                        .starred(starred)
                    Spacer(minLength: 6)
                    StarButton(starred: starred) {
                        if (starred) {
                            starredTeams.removeTeam(teamCode: teamCode)
                        } else {
                            starredTeams.addTeam(teamCode: teamCode)
                        }
                    }
                }
                Spacer(minLength: 30)
                Group {
                    GroupedView(title: "Season_param \(settings.getFormattedPrevSeason())" ) {
                        VStack {
                            StatsRowSingle(left: "Rank", right: "#\(standing.rank)")
                            StatsRowSingle(left: "Points", right: "\(standing.points)")
                            StatsRowSingle(left: "Games Played", right: "\(standing.gp)")
                            StatsRowSingle(left: "Points/Game", right: standing.getPointsPerGame())
                            StatsRowSingle(left: "Goal Diff", right: "\(standing.diff)")
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
                                if let p = players[0] {
                                    TopPlayerEntry(player: p, action: { self.selectedPlayer = p })
                                }
                                if let p = players[1] {
                                    TopPlayerEntry(player: p, action: { self.selectedPlayer = p })
                                }
                            }
                            Spacer(minLength: 20)
                            HStack(spacing: 20) {
                                if let p = players[2] {
                                    TopPlayerEntry(player: p, action: { self.selectedPlayer = p })
                                }
                                if let p = players[3] {
                                    TopPlayerEntry(player: p, action: { self.selectedPlayer = p })
                                }
                            }
                        }.padding(EdgeInsets(top: 0, leading: 15, bottom: 0, trailing: 15))
                    }
                }
                if let allPlayers = self.allPlayers {
                    Spacer(minLength: 30)
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
                        ForEach(allPlayers, id: \.player) { p in
                            Button(action: { self.selectedPlayer = p }) {
                                VStack(spacing: 0) {
                                        PlayerEntry(player: p)
                                    if p.player != allPlayers.last?.player {
                                        Divider()
                                            .padding(EdgeInsets(top: 0, leading: 30, bottom: 0, trailing: 30))
                                    }
                                }.contentShape(Rectangle()) // Make sure whole row is clickable
                            }.buttonStyle(ActiveButtonStyle())
                        }
                    }
                    Spacer(minLength: 10)
                }
                Group {
                    if (!liveGames.isEmpty) {
                        Group {
                            GroupedView(title: "Live") {
                                ForEach(liveGames) { (item) in
                                    LiveGame(game: item)
                                        .padding(EdgeInsets(top: 15, leading: 10, bottom: 15, trailing: 10))
                                }
                            }
                            Spacer()
                        }
                    }
                    Spacer(minLength: 30)
                    if (!futureGames.isEmpty) {
                        Group {
                            GroupedView(title: "Coming") {
                                
                                ForEach(futureGames) { (item) in
                                    ComingGame(game: item)
                                        .padding(EdgeInsets(top: 15, leading: 10, bottom: 15, trailing: 10))
                                }
                            }
                            Spacer()
                        }
                    }
                    Spacer(minLength: 30)
                    if (!playedGames.isEmpty) {
                        Group {
                            GroupedView(title: "Played_param \(settings.getFormattedPrevSeason())") {
                                ForEach(playedGames) { (item) in
                                    PlayedGame(game: item)
                                        .padding(EdgeInsets(top: 15, leading: 10, bottom: 15, trailing: 10))
                                }
                            }
                        }
                    }
                }
            }
            .background(Color(UIColor.systemGroupedBackground))
        }.background(Color(UIColor.systemGroupedBackground))
        .navigationBarTitle("", displayMode: .inline)
        .sheet(item: $selectedPlayer, onDismiss: {
            self.selectedPlayer = nil
        }) { p in
            if #available(iOS 16.0, *) {
                PlayerStatsSheet(player: p)
                    .presentationDetents([.medium, .large])
            } else {
                PlayerStatsSheet(player: p)
            }
        }
        .task { // runs before view appears
            await self.reloadPlayers()
        }
    }
    
    func reloadPlayers() async {
        if let players = await self.provider?.getPlayers(for: self.teamCode) {
            
            
            let gks = Array(players
                .filter({p in p.hasPlayed()})
                .filter({ p in p.position == "GK" })
                .sorted(by: { p1, p2 in p1.jersey >= p2.jersey })
                .sorted(by: { p1, p2 in p1.getGkScore() >= p2.getGkScore() }))
            
            self.topPlayers = Array(players
                .filter({p in p.hasPlayed()})
                .filter({ p in p.position != "GK" })
                .sorted(by: { p1, p2 in p1.jersey >= p2.jersey })
                .sorted(by: { p1, p2 in p1.getScore() >= p2.getScore() })
                .prefix(3))
            
            if gks.count > 0 {
                self.topPlayers?.insert(gks[0], at: 0)
            }
            
            self.allPlayers = players
                .filter({p in p.hasPlayed()})
                .filter({ p in !(self.topPlayers?.contains(where: { a in a.player == p.player }) ?? true) })
                .sorted(by: { p1, p2 in p1.getScore() >= p2.getScore() })
        }
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
                                                    getPlayedGame(), getPlayedGame(),
                                                    getFutureGame(), getFutureGame()]))
                .environmentObject(Settings())
                .environment(\.locale, .init(identifier: "sv"))
        }
    }
}

struct PlayerSheet_Previews: PreviewProvider {
    static var previews: some View {

        return PlayerStatsSheet(player: getPlayerStats(id: 206, g: 2, a: 3, pim: 41))
                .environmentObject(Settings())
                .environment(\.locale, .init(identifier: "sv"))
                .frame(height: 500, alignment: .top)
                .clipped()
    }
}

/*
 @available(iOS 16.0, *)
 struct PlayerPlusMinusChart_Previews: PreviewProvider {
 static var previews: some View {
 let data = [PlusMinusEntry(i: 0, d: 2),
 PlusMinusEntry(i: 1, d: -2),
 PlusMinusEntry(i: 2, d: 4),
 PlusMinusEntry(i: 3, d: 3),
 PlusMinusEntry(i: 4, d: 1),
 PlusMinusEntry(i: 5, d: 2),
 PlusMinusEntry(i: 6, d: -1),
 PlusMinusEntry(i: 7, d: 5),
 PlusMinusEntry(i: 8, d: -1),
 PlusMinusEntry(i: 9, d: -2),
 PlusMinusEntry(i: 10, d: 0),
 PlusMinusEntry(i: 11, d: 2),
 PlusMinusEntry(i: 12, d: 1),
 PlusMinusEntry(i: 13, d: 1),
 PlusMinusEntry(i: 14, d: 5),
 PlusMinusEntry(i: 15, d: 4),
 PlusMinusEntry(i: 16, d: 7),
 PlusMinusEntry(i: 17, d: 3),
 PlusMinusEntry(i: 18, d: -1),
 PlusMinusEntry(i: 19, d: -4),
 PlusMinusEntry(i: 20, d: -5),
 PlusMinusEntry(i: 21, d: 0),
 PlusMinusEntry(i: 22, d: 2),
 PlusMinusEntry(i: 23, d: 1),
 PlusMinusEntry(i: 24, d: 2),
 PlusMinusEntry(i: 25, d: 4),
 PlusMinusEntry(i: 26, d: 5),
 PlusMinusEntry(i: 27, d: 7),
 PlusMinusEntry(i: 28, d: 1),
 PlusMinusEntry(i: 29, d: 1),
 PlusMinusEntry(i: 30, d: 5),
 ]
 return PlayerPlusMinusChart(data: data)
 .frame(height: 100, alignment: .top)
 
 }
 }
 */
