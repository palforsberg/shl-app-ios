//
//  GamesStatsView.swift
//  shl-app-ios
//
//  Created by Pål on 2021-07-28.
//

import SwiftUI
import ActivityKit

struct PenaltyEventRow: View {
    var event: GameEvent
    @EnvironmentObject var teamsData: TeamsData
    var body: some View {
        HStack(spacing: 10) {
            TeamLogo(code: event.info.team ?? "", size: 28)
            VStack (spacing: 2) {
                HStack(spacing: 2) {
                    Text(LocalizedStringKey("Penalty"))
                    Image(systemName: "xmark.circle")
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundColor(Color(uiColor: .systemRed))
                        .opacity(0.9)
                        .offset(y: 1)
                    Spacer()
                    Text(event.info.penaltyLong ?? "")
                }.font(.system(size: 16, weight: .semibold, design: .rounded))
                .cornerRadius(10)
                HStack {
                    if let player = event.info.player {
                        Text("#\(player.jersey) \(player.firstName) \(player.familyName)").truncationMode(.tail).lineLimit(1)
                    }
                    Text(event.info.reason ?? "").truncationMode(.tail).lineLimit(1)
                    Spacer()
                    Text(event.gametime)
                }.font(.system(size: 14, weight: .medium, design: .rounded))
            }
            
        }.padding(EdgeInsets(top: 7, leading: 0, bottom: 7, trailing: 0))
            .foregroundColor(Color(uiColor: .secondaryLabel))    
    }
}

struct GoalEventRow: View {
    var event: GameEvent
    @EnvironmentObject var teamsData: TeamsData
    @EnvironmentObject var starredTeams: StarredTeams
    var body: some View {
        let team = event.info.team ?? ""
        let starred = starredTeams.isStarred(teamCode: team)

        HStack(spacing: 10) {
            TeamLogo(code: team, size: 28)
            VStack (spacing: 2) {
                HStack {
                    if starred {
                        Text(LocalizedStringKey("Goal_starred"))
                    } else {
                        Text(LocalizedStringKey("Goal"))
                    }
                    Spacer()
                    Text("\(event.info.homeResult)").underline(team == event.info.homeTeamId) +
                    Text(" - ") +
                    Text("\(event.info.awayResult)").underline(team == event.info.awayTeamId)
                }.font(.system(size: starred ? 20 : 20, weight: .heavy, design: .rounded))
                HStack {
                    if let player = event.info.player {
                        Text("#\(player.jersey) \(player.firstName) \(player.familyName)")
                    }
                    Text(event.info.getTeamAdvantage())
                    Spacer()
                    Text(event.gametime)
                }.font(.system(size: starred ? 14 : 14, weight: .semibold, design: .rounded))
            }
        }.padding(EdgeInsets(top: 10, leading: 0, bottom: 10, trailing: 0))
    }
}

struct GameStartEventRow: View {
    var event: GameEvent
    var body: some View {
        HStack {
            Text(LocalizedStringKey(self.event.type))
            Spacer()
        }
            .foregroundColor(Color(uiColor: UIColor.secondaryLabel))
            .font(.system(size: 14, weight: .semibold, design: .rounded))
            .padding(EdgeInsets(top: 2, leading: 37, bottom: 2, trailing: 0))
    }
}

struct PeriodEventRow: View {
    var event: GameEvent
    var body: some View {
        HStack {
            Text(self.getLocalizedString())
            Spacer()
        }
            .foregroundColor(Color(uiColor: UIColor.secondaryLabel))
            .font(.system(size: 14, weight: .semibold, design: .rounded))
            .padding(EdgeInsets(top: 2, leading: 37, bottom: 2, trailing: 0))
    }
    
    private func getLocalizedString() -> LocalizedStringKey {
        let periodNumber = event.info.periodNumber?.formatted() ?? "1"
        switch self.event.getEventType() {
        case .periodStart:
            if event.info.periodNumber == 99 {
                return LocalizedStringKey("PenaltiesStart")
            } else if (event.info.periodNumber ?? 0) >= 4 {
                return LocalizedStringKey("OvertimeStart")
            }
            return LocalizedStringKey("PeriodStart \(periodNumber)")
        case .periodEnd:
            if event.info.periodNumber == 99 {
                return LocalizedStringKey("PenaltiesEnd")
            } else if (event.info.periodNumber ?? 0) >= 4 {
                return LocalizedStringKey("OvertimeEnd")
            }
            return LocalizedStringKey("PeriodEnd \(periodNumber)")
        default: return LocalizedStringKey("")
        }
    }
}

struct GameEventRow: View {
    var event: GameEvent
    var body: some View {
        switch event.getEventType() {
        case.gameStart, .gameEnd: return AnyView(GameStartEventRow(event: event))
        case .goal: return AnyView(GoalEventRow(event: event))
        case .periodStart, .periodEnd: return AnyView(PeriodEventRow(event: event))
        case .penalty: return AnyView(PenaltyEventRow(event: event))
        default: return AnyView(Text(""))
        }
    }
}

struct GroupedView<Content: View>: View {
    var title: LocalizedStringKey?
    var cornerRadius = CGFloat(25)
    @ViewBuilder var content: () -> Content
    
    var body: some View {
        VStack(spacing: 0) {
            if let t = title {
                Text(t).listHeader(true)
                    .padding(.bottom, 6)
            }
            ZStack {
                RoundedRectangle(cornerRadius: cornerRadius)
                    .foregroundColor(Color(UIColor.secondarySystemGroupedBackground))
                VStack(spacing: 0) {
                    content()
                }
                // .cornerRadius(cornerRadius)
                .clipped()
            }
        }.padding(EdgeInsets(top: 0, leading: 15, bottom: 0, trailing: 15))
    }
}

struct StatsRow: View {
    var left: String
    var center: String
    var right: String
    
    var body: some View {
        HStack() {
            Text(left)
                .font(.system(size: 20, design: .rounded))
                .fontWeight(.heavy).frame(width: 45, alignment: .leading)
                .monospacedDigit()
            Spacer()
            Text(LocalizedStringKey(center))
                .font(.system(size: 18, design: .rounded))
                .fontWeight(.bold)
                .frame(maxWidth: .infinity, alignment: .center)
                .scaledToFit()
                .minimumScaleFactor(0.8)
            Spacer()
            Text(right)
                .font(.system(size: 20, design: .rounded))
                .fontWeight(.heavy).frame(width: 45, alignment: .trailing)
                .monospacedDigit()
        }.padding(EdgeInsets(top: 3, leading: 0, bottom: 3, trailing: 0))
    }
}

struct PeriodStatsView: View {
    let title: LocalizedStringKey
    let stats: Period?
    
    var body: some View {
        GroupedView(title: title) {
            VStack {
                StatsRow(left: "\(stats?.homeSOG ?? 0)", center: "Shots", right: "\(stats?.awaySOG ?? 0)")
                StatsRow(left: "\(stats?.homePIM ?? 0)", center: "Penalty Minutes", right: "\(stats?.awayPIM ?? 0)")
                StatsRow(left: "\(stats?.homeFOW ?? 0)", center: "Face Offs Won", right: "\(stats?.awayFOW ?? 0)")
                StatsRow(left: "\(stats?.homeHits ?? 0)", center: "Hits", right: "\(stats?.awayHits ?? 0)")
            }.padding(EdgeInsets(top: 16, leading: 30, bottom: 16, trailing: 30))
        }
    }
}

struct MatchHistoryView: View {
    
    @EnvironmentObject var gamesData: GamesData
    
    @State var prevHomeWins: Int = 0
    @State var prevHomeLoss: Int = 0
    
    var homeTeam: String
    var awayTeam: String
    
    var body: some View {
        Spacer(minLength: 10)
        HStack(spacing: 15) {
            TeamLogo(code: homeTeam)
            VStack(spacing: -2) {
                Text("\(self.prevHomeWins)").font(.system(size: 20, weight: .bold, design: .rounded))
                Text("Wins").font(.system(size: 13, design: .rounded))
            }
            Divider()
            VStack(spacing: -2) {
                Text("\(self.prevHomeLoss)").font(.system(size: 20, weight: .bold, design: .rounded))
                Text("Wins").font(.system(size: 13, design: .rounded))
            }
            TeamLogo(code: awayTeam)
        }
        .onAppear {
            let allPrevGames = self.gamesData.getGamesBetween(team1: homeTeam, team2: awayTeam)
            self.prevHomeWins = allPrevGames.filter({ $0.didWin(homeTeam) }).count
            self.prevHomeLoss = allPrevGames.filter({ !$0.didWin(homeTeam) }).count
        }
    }
}

struct TopPlayerView: View {
    var player: Player
    var body: some View {
        VStack {
            HStack {
                TeamLogo(code: player.team, size: 19)
                Text("\(player.firstName) \(player.familyName)").fontWeight(.semibold).font(.system(size: 16, design: .rounded))
                Text("\(player.position)").fontWeight(.regular).font(.system(size: 16, design: .rounded))
                Spacer()
                Text("#\(player.jersey)").fontWeight(.semibold).font(.system(size: 15, design: .rounded))
            }.padding(.bottom, -4)
            HStack {
                Text("G \(player.g)").fontWeight(.semibold).font(.system(size: 14, design: .rounded)).opacity(player.g == 0 ? 0.4 : 1)
                Text("A \(player.a)").fontWeight(.semibold).font(.system(size: 14, design: .rounded)).opacity(player.a == 0 ? 0.4 : 1)
                Text("PIM \(player.pim)").fontWeight(.semibold).font(.system(size: 14, design: .rounded)).opacity(player.pim == 0 ? 0.4 : 1)
                if let toi = player.toi {
                    Text("TOI \(toi)").fontWeight(.semibold).font(.system(size: 14, design: .rounded)).opacity(0.4)
                }
                Spacer()
            }.padding(.leading, 27)
        }
    }
}


struct PuckText: View {
    @State var animate: Bool = false
    var body: some View {
        Text("•")
            .offset(x: animate ? 1.5 : -1.5)
            .animation(.easeOut(duration: 0.3).repeatForever(), value: animate)
            .onAppear(){
                self.animate = true
            }
    }
}
struct GamesStatsView: View {
    @State var gameStats: GameStats?
    @State var previousGames: [Game] = []
    @State var topPlayers: [Player] = []
    @State var hasFetched = false
    @State var liveActivityEnabled = false

    @EnvironmentObject var gamesData: GamesData
    @EnvironmentObject var starredTeams: StarredTeams
    @EnvironmentObject var teamsData: TeamsData
    @EnvironmentObject var settings: Settings
    @EnvironmentObject var standings: StandingsData
    
    var provider: DataProvider? = DataProvider()

    var game: Game
    
    var body: some View {
            ScrollView {
                if #available(iOS 16.0, *) {
                } else {
                    PullToRefresh(coordinateSpaceName: "game_stats_scrollview") {
                        Task {
                            await self.reloadData()
                        }
                    }
                }
                Spacer(minLength: 10)
                Group {
                    Text("Swedish Hockey League")
                    Text(LocalizedStringKey(game.getGameType()?.rawValue ?? ""))
                }
                .font(.system(size: 15, weight: .semibold, design: .rounded))
                .foregroundColor(Color(UIColor.secondaryLabel))
                Spacer(minLength: 15)
                Group { // Header
                    HStack(alignment: .center, spacing: 0) {
                        VStack {
                            TeamLogo(code: game.home_team_code, size: 50.0)
                            Text(teamsData.getShortname(game.home_team_code))
                                .font(.system(size: 20, weight: .bold, design: .rounded))
                                .starred(starredTeams.isStarred(teamCode: game.home_team_code))
                                .scaledToFit()
                                .minimumScaleFactor(0.6)
                                
                        }.frame(width: /*@START_MENU_TOKEN@*/100/*@END_MENU_TOKEN@*/, height: 80).frame(maxWidth: 140)
                
                        HStack(alignment: .center, spacing: 15) {
                            Text("\(gameStats?.recaps.gameRecap?.homeG ?? game.home_team_result)")
                                .font(.system(size: 40, weight: .heavy, design: .rounded))
                                .scaledToFit()
                                .minimumScaleFactor(0.6)
                            Text("vs").font(.system(size: 20, weight: .bold, design: .rounded)).padding(.top, 2)
                            Text("\(gameStats?.recaps.gameRecap?.awayG ?? game.away_team_result)")
                                .font(.system(size: 40, weight: .heavy, design: .rounded))
                                .scaledToFit()
                                .minimumScaleFactor(0.6)
                        }.padding(EdgeInsets(top: 0, leading: 5, bottom: 0, trailing: 5))
                        
                        VStack {
                            TeamLogo(code: game.away_team_code, size: 50)
                            Text(teamsData.getShortname(game.away_team_code))
                                .font(.system(size: 20, weight: .bold, design: .rounded))
                                .starred(starredTeams.isStarred(teamCode: game.away_team_code))
                                .scaledToFit()
                                .minimumScaleFactor(0.6)

                        }.frame(width: /*@START_MENU_TOKEN@*/100/*@END_MENU_TOKEN@*/, height: 80).frame(maxWidth: 140)
                    }.frame(maxWidth: .infinity)
                }
                HStack(spacing: 6) {
                    if (game.isFuture()) {
                        Text(game.start_date_time.getFormattedDate())
                        Text(game.start_date_time.getFormattedTime())
                    } else {
                        if let periodString = gameStats?.status {
                            Text(LocalizedStringKey(periodString))
                        }
                        if gameStats?.getStatus()?.isGameTimeApplicable() ?? false,
                           gameStats?.report?.gametime != nil {
                            Text("•")
                        }
                        if gameStats?.getStatus()?.isGameTimeApplicable() ?? false,
                           let gt = gameStats?.report?.gametime {
                            Text(gt)
                        }
                    }
                }
                .font(.system(size: 20, weight: .heavy, design: .rounded))
                .padding(.top, -26)
                
                if #available(iOS 16.1, *),
                   LiveActivity.shared?.isGameApplicable(game: game) ?? false,
                   ActivityAuthorizationInfo().areActivitiesEnabled
                {
                    Group {
                        if self.liveActivityEnabled {
                            Spacer(minLength: 10)
                            Text("live aktiviteten lever på låsskärmen")
                                .font(.system(size: 12, weight: .bold, design: .rounded))
                                .foregroundColor(Color(uiColor: .tertiaryLabel))
                            Spacer(minLength: 15)
                        } else {
                            Spacer(minLength: 20)
                            Button("Start Live") { self.startLiveActivity(for: game) }
                            Spacer(minLength: 20)
                        }
                    }
                    .buttonStyle(.bordered)
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    
                } else if game.isFuture() {
                    Spacer(minLength: 24)
                    VStack(spacing: 5) {
                        Text("Starts In").listHeader(false)
                        TimerView(referenceDate: game.start_date_time)
                    }
                    Spacer(minLength: 30)
                } else {
                    Spacer(minLength: 20)
                }
                
                if let period = gameStats?.recaps.gameRecap {
                    PeriodStatsView(title: "Match Detail", stats: period)
                    Spacer(minLength: 25)
                } else if game.isFuture(),
                          let homeRank = standings.getFor(team: game.home_team_code),
                          let awayRank = standings.getFor(team: game.away_team_code) {
                      GroupedView(title: "GamePreview") {
                          VStack {
                              StatsRow(left: "#\(homeRank.rank)", center: "Rank", right: "#\(awayRank.rank)")
                              StatsRow(left: "\(homeRank.diff)", center: "Goal Diff", right: "\(awayRank.diff)")
                              StatsRow(left: "\(homeRank.getPointsPerGame())", center: "Points/Game", right: "\(awayRank.getPointsPerGame())")
                              HStack(alignment: .bottom) {
                                  FormGraph(teamCode: game.home_team_code)
                                  Spacer()
                                  Text(LocalizedStringKey("Form"))
                                      .font(.system(size: 18, design: .rounded))
                                      .fontWeight(.bold)
                                      .frame(maxWidth: .infinity, alignment: .center)
                                      .scaledToFit()
                                      .minimumScaleFactor(0.8)
                                  Spacer()
                                  FormGraph(teamCode: game.away_team_code)
                              }.padding(EdgeInsets(top: 3, leading: 0, bottom: 3, trailing: 0))
                          }.padding(EdgeInsets(top: 16, leading: 30, bottom: 16, trailing: 30))
                      }
                      Spacer(minLength: 30)
                    
                }
                if hasFetched { // hide until all data has been fetched to avoid jumping UI
                    if !(gameStats?.events ?? []).isEmpty {
                        Spacer(minLength: 0)
                        Group {
                            ForEach(gameStats!.events!) { p in
                                GameEventRow(event: p)
                            }
                        }.padding(EdgeInsets(top: 0, leading: 30, bottom: 0, trailing: 35))
                        Spacer(minLength: 30)
                        Divider()
                        Spacer(minLength: 20)
                    } else  if !topPlayers.isEmpty {
                        Group {
                            ForEach(topPlayers) { p in
                                TopPlayerView(player: p)
                            }
                        }.padding(EdgeInsets(top: 7, leading: 30, bottom: 8, trailing: 35))
                        Spacer(minLength: 30)
                    }
            
                    MatchHistoryView(homeTeam: game.home_team_code, awayTeam: game.away_team_code)
                    Spacer(minLength: 10)
                    if (!previousGames.isEmpty) {
                        GroupedView(title: "", cornerRadius: 15) {
                            ForEach(previousGames) { (item) in
                                NavigationLink(destination: GamesStatsView(game: item)) {
                                    PlayedGame(game: item)
                                        .padding(EdgeInsets(top: 15, leading: 10, bottom: 10, trailing: 10))
                                    if item.game_id != previousGames.last?.game_id {
                                        Divider()
                                            .padding(EdgeInsets(top: 0, leading: 20, bottom: 0, trailing: 20))
                                    }
                                }
                                .buttonStyle(ActiveButtonStyle())
                            }
                        }
                        Spacer(minLength: 40)
                    }
                }
            }
            .task { // runs before view appears
                
                let allPrevGames = self.gamesData.getGamesBetween(team1: game.home_team_code, team2: game.away_team_code)
                self.previousGames = allPrevGames.filter({ $0.game_uuid != game.game_uuid })
                
                self.liveActivityEnabled = LiveActivity.shared?.isEnabled(gameUuid: game.game_uuid) ?? false
                LiveActivity.shared?.setListener(game_uuid: game.game_uuid) { active in
                    print("[LIVE?] \(active)")
                    withAnimation {
                        self.liveActivityEnabled = active
                    }
                }
                Task {
                    await self.reloadData()
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: .onGameNotification)) { data in
                Task {
                    if (data.object as? GameNofitication)?.game_uuid == game.game_uuid {
                        await self.reloadData()
                    }
                }
            }
            .refreshable {
                await self.reloadData()
            }
            .navigationBarTitle("", displayMode: .inline)
            .background(Color(UIColor.systemGroupedBackground))
            .coordinateSpace(name: "game_stats_scrollview")
    }
    
    func reloadData() async {
        if let stats = await provider?.getGameStats(game: game) {
            self.gameStats = stats
            self.gameStats!.events = GamesStatsView.handleEvents(self.gameStats?.events)
            self.topPlayers = stats.getTopPlayers()
            self.hasFetched = true
        }
        if provider == nil {
            self.topPlayers = self.gameStats?.getTopPlayers() ?? []
            self.hasFetched = true
        }
    }
    
    
    @available(iOS 16.1, *)
    func startLiveActivity(for game: Game) {
        Task {
            await LiveActivity.shared?.startLiveActivity(for: game)
        }
    }
    
    @available(iOS 16.1, *)
    func endLiveActivity(for game: Game) {
        Task {
            await LiveActivity.shared?.endLiveActivity(for: game)
        }
    }
    
    static func handleEvents(_ events: [GameEvent]?) -> [GameEvent] {
        guard events != nil else {
            return []
        }
        return events!.reversed()
            .enumerated()
            .filter({ $0.element.getEventType() != nil })
            .filter { a in
                if (a.element.getEventType() == .periodEnd) {
                    return a.offset == 0
                }
                return true
            }
            .map({ $0.element })
    }
}

struct GamesStatsView_Previews: PreviewProvider {
    static var previews: some View {
        let teams = getTeamsData()
        let allPeriods = AllPeriods(gameRecap: getPeriod(),
                                    period1: getPeriod(),
                                    period2: getPeriod(),
                                    period3: getPeriod()
        )
        
        let events: [GameEvent] = GamesStatsView.handleEvents([
            getEvent(type: .gameStart),
            getEvent(type: .periodStart, period: 1),
            getEvent(type: .penalty),
            getEvent(type: .periodEnd),
            getEvent(type: .periodStart, period: 2),
            getEvent(type: .goal),
            getEvent(type: .goal, period: 2, team: "FHC"),
            getEvent(type: .penalty),
            getEvent(type: .periodEnd, period: 2),
            getEvent(type: .periodStart, period: 99),
            getEvent(type: .goal),
        ])
        let standings = [
            getStanding("LHF", rank: 1),
            getStanding("FHC", rank: 12),
        ]
        
        let starredTeams = StarredTeams()
        starredTeams.addTeam(teamCode: "LHF")
        
        let report = GameReport(gametime: "13:27", timePeriod: 444, period: 1, gameState: "Ongoing")
        return GamesStatsView(gameStats: GameStats(recaps: allPeriods,
                                                   gameState: "Ongoing",
                                                   playersByTeam: getPlayers(),
                                                   status: "Period1",
                                                   events: events,
                                                   report: report),
                              provider: nil,
                              game: getLiveGame())
            .environmentObject(GamesData(data: [getPlayedGame(), getPlayedGame(), getPlayedGame()]))
            .environmentObject(teams)
            .environmentObject(Settings())
            .environmentObject(starredTeams)
            .environmentObject(StandingsData(data: standings))
            .environment(\.locale, .init(identifier: "sv"))
    }
    
    static func getPeriod() -> Period {
        return Period(periodNumber: 0, homeG: 3, awayG: 0, homeHits: 14, homeSOG: 64, homePIM: 654, homeFOW: 55, awayHits: 53, awaySOG: 23, awayPIM: 23, awayFOW: 0)
    }
}

struct GamesStatsView_Played_Previews: PreviewProvider {
    static var previews: some View {
        let teams = getTeamsData()
        let allPeriods = AllPeriods(gameRecap: getPeriod(),
                                    period1: getPeriod(),
                                    period2: getPeriod(),
                                    period3: getPeriod()
        )
        
        let events: [GameEvent] = GamesStatsView.handleEvents([
            getEvent(type: .gameStart),
            getEvent(type: .periodStart, period: 1),
            getEvent(type: .penalty),
            getEvent(type: .periodEnd),
            getEvent(type: .periodStart, period: 2),
            getEvent(type: .goal),
            getEvent(type: .goal, period: 2, team: "FHC"),
            getEvent(type: .penalty),
            getEvent(type: .periodEnd, period: 2),
            getEvent(type: .periodStart, period: 99),
            getEvent(type: .goal),
            getEvent(type: .periodEnd, period: 99),
        ])
        let standings = [
            getStanding("LHF", rank: 1),
            getStanding("FHC", rank: 12),
        ]
        
        let starredTeams = StarredTeams()
        starredTeams.addTeam(teamCode: "LHF")
        
        let report = GameReport(gametime: "00:00", timePeriod: 444, period: 3, gameState: "Finished")
        return GamesStatsView(gameStats: GameStats(recaps: allPeriods,
                                                   gameState: "Finished",
                                                   playersByTeam: getPlayers(),
                                                   status: "Finished",
                                                   events: events,
                                                   report: report),
                              provider: nil,
                              game: getPlayedGame(t1: "LHF", s1: 3, t2: "FHC", s2: 0, overtime: false, date: Date().addingTimeInterval(TimeInterval(-2_000_000))))
            .environmentObject(GamesData(data: [getPlayedGame(), getPlayedGame(), getPlayedGame()]))
            .environmentObject(teams)
            .environmentObject(Settings())
            .environmentObject(starredTeams)
            .environmentObject(StandingsData(data: standings))
            .environment(\.locale, .init(identifier: "sv"))
    }
    
    static func getPeriod() -> Period {
        return Period(periodNumber: 0, homeG: 3, awayG: 0, homeHits: 14, homeSOG: 64, homePIM: 654, homeFOW: 55, awayHits: 53, awaySOG: 23, awayPIM: 23, awayFOW: 0)
    }
}


struct GamesStatsView_No_Events_Previews: PreviewProvider {
    static var previews: some View {
        let teams = getTeamsData()
        let allPeriods = AllPeriods(gameRecap: getPeriod(),
                                    period1: getPeriod(),
                                    period2: getPeriod(),
                                    period3: getPeriod()
        )
        
        let standings = [
            getStanding("LHF", rank: 1),
            getStanding("FHC", rank: 12),
        ]
        
        let starredTeams = StarredTeams()
        starredTeams.addTeam(teamCode: "LHF")
        return GamesStatsView(gameStats: GameStats(recaps: allPeriods,
                                                   gameState: "Ongoing",
                                                   playersByTeam: getPlayers(),
                                                   status: "Period1",
                                                   events: nil),
                              provider: nil,
                              game: getLiveGame())
            .environmentObject(GamesData(data: [getPlayedGame(), getPlayedGame(), getPlayedGame()]))
            .environmentObject(teams)
            .environmentObject(Settings())
            .environmentObject(starredTeams)
            .environmentObject(StandingsData(data: standings))
            .environment(\.locale, .init(identifier: "sv"))
    }
    
    static func getPeriod() -> Period {
        return Period(periodNumber: 0, homeG: 3, awayG: 0, homeHits: 14, homeSOG: 64, homePIM: 654, homeFOW: 55, awayHits: 53, awaySOG: 23, awayPIM: 23, awayFOW: 0)
    }
}


struct GamesStatsView_Future_Game_Previews: PreviewProvider {
    static var previews: some View {
        let teams = getTeamsData()
        let standings = [
            getStanding("LHF", rank: 1),
            getStanding("FHC", rank: 12),
        ]
        
        let starred = StarredTeams()
        starred.addTeam(teamCode: "LHF")
        return GamesStatsView(gameStats: GameStats(recaps: AllPeriods(), gameState: "", playersByTeam: getPlayersWithZeroScore()),
                              provider: nil,
                              game: getFutureGame())
            .environmentObject(GamesData(data: [getPlayedGame(), getPlayedGame(), getPlayedGame()]))
            .environmentObject(teams)
            .environmentObject(Settings())
            .environmentObject(starred)
            .environmentObject(StandingsData(data: standings))
            .environment(\.locale, .init(identifier: "sv"))
    }
    
    static func getPeriod() -> Period {
        return Period(periodNumber: 0, homeG: 3, awayG: 0, homeHits: 14, homeSOG: 64, homePIM: 654, homeFOW: 55, awayHits: 53, awaySOG: 23, awayPIM: 23, awayFOW: 0)
    }
}

struct GamesStatsView_Future_No_Prev_Game_Previews: PreviewProvider {
    static var previews: some View {
        let teams = getTeamsData()
        let allPeriods = AllPeriods(gameRecap: nil)
        
        let standings = [
            getStanding("LHF", rank: 1),
            getStanding("FHC", rank: 12),
        ]
        return GamesStatsView(gameStats: GameStats(recaps: allPeriods, gameState: "GameEnded", playersByTeam: getPlayersWithZeroScore()),
                              provider: nil,
                              game: getFutureGame())
            .environmentObject(GamesData(data: []))
            .environmentObject(teams)
            .environmentObject(Settings())
            .environmentObject(StandingsData(data: standings))
            .environmentObject(StarredTeams())
            .environment(\.locale, .init(identifier: "sv"))
    }
    
    static func getPeriod() -> Period {
        return Period(periodNumber: 0, homeG: 3, awayG: 0, homeHits: 14, homeSOG: 64, homePIM: 654, homeFOW: 55, awayHits: 53, awaySOG: 23, awayPIM: 23, awayFOW: 0)
    }
}
