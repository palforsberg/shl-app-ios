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
            TeamLogo(code: event.team ?? "", size: 28)
            VStack (spacing: 2) {
                HStack(spacing: 2) {
                    Text(LocalizedStringKey("Penalty"))
                    Image(systemName: "xmark.circle")
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundColor(Color(uiColor: .systemRed))
                        .opacity(0.9)
                        .offset(y: 1)
                    Spacer()
                    Text(event.penalty ?? "")
                }.font(.system(size: 16, weight: .semibold, design: .rounded))
                .cornerRadius(10)
                HStack {
                    if let player = event.player {
                        Text("#\(player.jersey) \(player.first_name) \(player.family_name)").truncationMode(.tail).lineLimit(1)
                    }
                    Text(event.reason ?? "").truncationMode(.tail).lineLimit(1)
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
    var game: Game
    @EnvironmentObject var teamsData: TeamsData
    @EnvironmentObject var starredTeams: StarredTeams
    var body: some View {
        let team = event.team ?? ""
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
                    Text("\(event.home_team_result ?? 0)").underline(team == game.home_team_code) +
                    Text(" - ") +
                    Text("\(event.away_team_result ?? 0)").underline(team == game.away_team_code)
                }.font(.system(size: starred ? 20 : 20, weight: .heavy, design: .rounded))
                HStack {
                    if let player = event.player {
                        Text("#\(player.jersey) \(player.first_name) \(player.family_name)")
                    }
                    Text(event.getTeamAdvantage())
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
        
        switch self.event.getEventType() {
        case .periodStart:
            if event.status == "Shootout" {
                return LocalizedStringKey("PenaltiesStart")
            } else if event.status == "Overtime" {
                return LocalizedStringKey("OvertimeStart")
            }
            return LocalizedStringKey("PeriodStart \(getPeriod(s: event.status))")
        case .periodEnd:
            if event.status == "Shootout" {
                return LocalizedStringKey("PenaltiesEnd")
            } else if event.status == "Overtime" {
                return LocalizedStringKey("OvertimeEnd")
            }
            return LocalizedStringKey("PeriodEnd \(getPeriod(s: event.status))")
        default: return LocalizedStringKey("")
        }
    }
    
    private func getPeriod(s: String) -> String {
        switch s {
        case "Period1": return "1"
        case "Period2": return "2"
        case "Period3": return "3"
        default: return "1"
        }
    }
}

struct GameEventRow: View {
    var event: GameEvent
    var game: Game
    var body: some View {
        switch event.getEventType() {
        case.gameStart, .gameEnd: return AnyView(GameStartEventRow(event: event))
        case .goal: return AnyView(GoalEventRow(event: event, game: game))
        case .periodStart, .periodEnd: return AnyView(PeriodEventRow(event: event))
        case .penalty: return AnyView(PenaltyEventRow(event: event))
        default: return AnyView(Text(""))
        }
    }
}

struct GroupedView<Content: View>: View {
    var title: LocalizedStringKey?
    var cornerRadius = CGFloat(15)
    var backgroundColor = Color(UIColor.secondarySystemGroupedBackground)
    @ViewBuilder var content: () -> Content
    
    var body: some View {
        VStack(spacing: 0) {
            if let t = title {
                Text(t).listHeader(true)
                    .padding(.bottom, 2)
            }
            ZStack {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .foregroundColor(self.backgroundColor)
                    .overlay(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .strokeBorder(.gray.opacity(0.3)))
                
                VStack(spacing: 0) {
                    content()
                }
                .cornerRadius(cornerRadius)
                .clipped()
            }
        }.padding(EdgeInsets(top: 0, leading: 15, bottom: 0, trailing: 15))
    }
}

struct RoundedSection<Content: View>: View {
    var cornerRadius = CGFloat(25)
    @ViewBuilder var content: () -> Content
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: cornerRadius)
                .strokeBorder(.gray.opacity(0.3))
                .background(RoundedRectangle(cornerRadius: cornerRadius).foregroundColor( Color(UIColor.secondarySystemGroupedBackground)))
            content()
            .clipped()
        }
    }
}

struct StatsRow: View {
    var left: String
    var center: String
    var right: String
    
    var body: some View {
        HStack() {
            Text(left)
                .rounded(size: 20, weight: .heavy)
                .frame(width: 65, alignment: .leading)
                .monospacedDigit()
            Spacer()
            Text(LocalizedStringKey(center))
                .rounded(size: 18, weight: .bold)
                .scaledToFit()
                .minimumScaleFactor(0.8)
            Spacer()
            Text(right)
                .rounded(size: 20, weight: .heavy)
                .frame(width: 65, alignment: .trailing)
                .monospacedDigit()
        }
        .padding(.vertical, 3)
    }
}

struct StatsView: View {
    let title: LocalizedStringKey
    let stats: ApiGameStats
    
    var body: some View {
        GroupedView(title: title) {
            VStack {
                StatsRow(left: "\(stats.home.sog)", center: "Shots", right: "\(stats.away.sog)")
                StatsRow(left: "\(stats.home.pim)", center: "Penalty Minutes", right: "\(stats.away.pim)")
                StatsRow(left: "\(stats.home.fow)", center: "Face Offs Won", right: "\(stats.away.fow)")
            }
            .padding(.vertical, 15)
            .padding(.horizontal, 30)
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

struct PickemSliderView: View {
    @Namespace var animation
    @EnvironmentObject var pickemData: PickemData
    
    var game: Game
    @State var picked: String?
    
    var onVote: (VotesPerGame?) -> ()
    
    var body: some View {
        let home_team = game.home_team_code
        let away_team = game.away_team_code
        let home_perc = game.votes?.home_perc ?? 50
        let home_val = "\(home_perc)%"
        let away_perc = game.votes?.away_perc ?? 50
        let away_val = "\(away_perc)%"
        let pickable = PickemData.isPickable(game: game)
        let show_perc = picked != nil || !pickable
        let height: CGFloat = pickable ? 54 : 44

        GeometryReader { geometry in
            HStack(spacing: 0) {
                Button { self.vote(team: home_team) } label: {
                    HStack() {
                        TeamLogo(code: home_team, size: 28)
                        if home_team == picked {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(Color(uiColor: .label))
                                .matchedGeometryEffect(id: "checkmark", in: animation)
                        }
                        Spacer()
                        Text(home_val)
                            .rounded(size: 13, weight: .heavy)
                            .foregroundColor(picked == home_team ? Color(uiColor: .label) : Color(uiColor: .secondaryLabel))
                            .opacity(show_perc ? 1 : 0)
                            .id("home.perc")
                    }
                }
                .padding(.leading, 12).padding(.trailing, 6)
                .frame(width: geometry.size.width * self.getWidthPerc(votes: home_perc))
                .frame(height: height)
                
                Rectangle()
                    .foregroundColor(.gray.opacity(0.3))
                    .frame(width: 1, height: height-2)
                    .matchedGeometryEffect(id: "middle-line", in: animation)
                
                Button { self.vote(team: away_team) } label: {
                    HStack() {
                        Text(away_val)
                            .rounded(size: 13, weight: .heavy)
                            .foregroundColor(picked == away_team ? Color(uiColor: .label) : Color(uiColor: .secondaryLabel))
                            .opacity(show_perc ? 1 : 0)
                            .id("away.perc")
                        Spacer()
                        if away_team == picked {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(Color(uiColor: .label))
                                .matchedGeometryEffect(id: "checkmark", in: animation)
                        }
                        TeamLogo(code: away_team, size: 28)
                    }
                }
                .padding(.leading, 6).padding(.trailing, 12)
                .frame(width: geometry.size.width * self.getWidthPerc(votes: away_perc))
                .frame(height: height)
              }
            .frame(width: geometry.size.width)
            .background(Color(UIColor.secondarySystemGroupedBackground))
            .cornerRadius(15)
            .overlay(RoundedRectangle(cornerRadius: 15, style: .continuous)
                .strokeBorder(.gray.opacity(0.3), lineWidth: 1))
        }
        .frame(height: height)
        .disabled(!pickable)
        .opacity(pickable ? 1 : 0.8)
        .id("pick.select.\(game.game_uuid)")
        .onReceive(pickemData.objectWillChange) { pd in
            let newPicked = self.pickemData.getPicked(gameUuid: game.game_uuid)
            if newPicked != self.picked {
                withAnimation(.spring()) {
                    self.picked = newPicked
                }
            }
        }
        .onAppear {
            self.picked = self.pickemData.getPicked(gameUuid: game.game_uuid)
        }
    }
    
    func vote(team: String) {
        guard team != self.picked, PickemData.isPickable(game: game) else {
            return
        }
        Task {
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            onVote(await pickemData.vote(gameUuid: game.game_uuid, team: team))
        }
    }
    
    func getWidthPerc(votes: Int) -> CGFloat {
        guard self.picked != nil else {
            return 0.5
        }
        return min(0.65, max(0.35, CGFloat(votes) / 100.0))
    }
}

struct PuckText: View {
    @State var animate: Bool = false
    var body: some View {
        Text("•")
            .offset(x: animate ? 1.5 : -1.5)
            .animation(.easeOut(duration: 0.3).repeatForever(), value: animate)
            .onAppear {
                self.animate = true
            }
    }
}

struct GamesStatsView: View {
    @State var details: GameDetails?
    @State var previousGames: [Game] = []
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
        let game = details?.game ?? game
            ScrollView {
                #if DEBUG
                NavigationLink("Update Report") {
                    UpdateReportView(game: game)
                }
                #endif
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
                    Text("\(game.league.rawValue) • \(settings.getFormattedSeason())")
                    Text(LocalizedStringKey(game.getGameType()?.rawValue ?? ""))
                }
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundColor(Color(UIColor.secondaryLabel))
                Spacer(minLength: 15)
                Group { // Header
                    HStack(alignment: .top, spacing: 0) {
                        VStack {
                            TeamLogo(code: game.home_team_code, size: 50.0)
                            Text(teamsData.getShortname(game.home_team_code))
                                .rounded(size: 17, weight: .bold)
                                .starred(starredTeams.isStarred(teamCode: game.home_team_code))
                                .scaledToFit()
                                .minimumScaleFactor(0.6)
                                
                        }.frame(width: /*@START_MENU_TOKEN@*/100/*@END_MENU_TOKEN@*/).frame(maxWidth: 140)
                
                        VStack(spacing: 8) {
                            HStack(alignment: .center, spacing: 8) {
                                Text("\(game.home_team_result)")
                                    .font(.system(size: 40, weight: .heavy, design: .rounded))
                                    .scaledToFit()
                                    .minimumScaleFactor(0.6)
                                Text(":").rounded(size: 20, weight: .heavy).padding(.top, 2)
                                Text("\(game.away_team_result)")
                                    .font(.system(size: 40, weight: .heavy, design: .rounded))
                                    .scaledToFit()
                                    .minimumScaleFactor(0.6)
                            }
                            .padding(EdgeInsets(top: 3, leading: 5, bottom: 0, trailing: 5))
                            .opacity(game.isFuture() ? 0.2 : 1.0)
                            HStack(spacing: 3) {
                                if (game.isFuture()) {
                                    Text("\(game.start_date_time.getFormattedDate()) • \(game.start_date_time.getFormattedTime())")
                                        .foregroundColor(Color(uiColor: .secondaryLabel))
                                } else {
                                    if let statusString = game.status {
                                        Text(LocalizedStringKey(statusString))
                                    }
                                    if game.getStatus()?.isGameTimeApplicable() ?? false,
                                       let gt = game.gametime {
                                        Text("•")
                                        Text(gt)
                                    }
                                }
                            }
                            .lineLimit(1)
                            .scaledToFit()
                            .minimumScaleFactor(0.5)
                            .padding(EdgeInsets(top: 2, leading: 5, bottom: 2, trailing: 5))
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                        }
                        
                        VStack {
                            TeamLogo(code: game.away_team_code, size: 50)
                            Text(teamsData.getShortname(game.away_team_code))
                                .rounded(size: 16, weight: .bold)
                                .starred(starredTeams.isStarred(teamCode: game.away_team_code))
                                .scaledToFit()
                                .minimumScaleFactor(0.6)
                        }.frame(width: /*@START_MENU_TOKEN@*/100/*@END_MENU_TOKEN@*/).frame(maxWidth: 140)
                    }.frame(maxWidth: .infinity)
                }
                
                
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
                                .cornerRadius(10)
                                .overlay(RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .strokeBorder(.gray.opacity(0.3)))
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
                
                if let stats = details?.stats {
                    StatsView(title: "Match Detail", stats: stats)
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
                if game.votes != nil || PickemData.isPickable(game: game) {
                    Group {
                        Text("Pick'em").listHeader()
                            .padding(.bottom, -3)
                        PickemSliderView(game: game, onVote: self.updateVote)
                            .padding(.leading, 15).padding(.trailing, 15)
                        Spacer(minLength: 40)
                    }
                }
                if hasFetched { // hide until all data has been fetched to avoid jumping UI
                    if !(details?.events.isEmpty ?? false) {
                        Spacer(minLength: 0)
                        Group {
                            ForEach(details?.events ?? []) { p in
                                GameEventRow(event: p, game: game)
                            }
                        }.padding(EdgeInsets(top: 0, leading: 30, bottom: 0, trailing: 35))
                        Spacer(minLength: 30)
                        Divider()
                        Spacer(minLength: 20)
                    }
            
                    MatchHistoryView(homeTeam: game.home_team_code, awayTeam: game.away_team_code)
                    Spacer(minLength: 10)
                    if (!previousGames.isEmpty) {
                        GroupedView(title: "") {
                            VStack(spacing: 0) {
                                ForEach(previousGames) { item in
                                    NavigationLink(destination: GamesStatsView(game: item)) {
                                        PlayedGame(game: item)
                                            .padding(.vertical, 20)
                                            .contentShape(Rectangle())
                                    }
                                    .buttonStyle(ActiveButtonStyle())
                                    if item != previousGames.last {
                                        Divider()
                                    }
                                }
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
        if let details = await provider?.getGameDetails(game_uuid: game.game_uuid) {
            self.details = details
            self.details!.events = GamesStatsView.handleEvents(self.details?.events)
            self.hasFetched = true
        }
        if provider == nil {
            self.hasFetched = true
        }
    }
    
    func updateVote(_ votes: VotesPerGame?) {
        if let votes = votes {
            withAnimation(.spring()) {
                self.details?.game.votes = votes
            }
        }
    }
    
    @available(iOS 16.1, *)
    func startLiveActivity(for game: Game) {
        Task {
            await LiveActivity.shared?.startLiveActivity(for: game, teamsData: teamsData)
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
        let stats = ApiGameStats(home: ApiGameTeamStats(g: 2, sog: 24, pim: 42, fow: 2), away: ApiGameTeamStats(g: 0, sog: 42, pim: 3, fow: 2))
        
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
        let starredTeams = StarredTeams()
        starredTeams.addTeam(teamCode: "SAIK")
        let game = getLiveGame(t1: "SAIK", score1: 4, t2: "IKO", score2: 2, status: "Overtime")
        PickemData.updateStored(key: "picks.\(Settings.currentSeason)", picks: [Pick(gameUuid: game.game_uuid, pickedTeam: "SAIK")])
        return GamesStatsView(details: GameDetails(game: game, events: events, stats: stats, players: [getPlayer(id: 5434, g: 2, a: 3, pim: 2)]),
                              provider: nil,
                              game: game)
            .environmentObject(GamesData(data: [getPlayedGame(), getPlayedGame(), getPlayedGame()]))
            .environmentObject(teams)
            .environmentObject(Settings())
            .environmentObject(getPickemData())
            .environmentObject(starredTeams)
            .environmentObject(getStandingsData())
            .environment(\.locale, .init(identifier: "sv"))
    }
}

struct GamesStatsView_Played_Previews: PreviewProvider {
    static var previews: some View {
        let teams = getTeamsData()
        let stats = ApiGameStats(home: ApiGameTeamStats(g: 2, sog: 24, pim: 42, fow: 2), away: ApiGameTeamStats(g: 0, sog: 42, pim: 3, fow: 2))
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
        
        let starredTeams = StarredTeams()
        starredTeams.addTeam(teamCode: "LHF")
        
        return GamesStatsView(details: GameDetails(game: getLiveGame(), events: events, stats: stats, players: []),
                              provider: nil,
                              game: getPlayedGame(t1: "LHF", s1: 3, t2: "FHC", s2: 0, overtime: false, date: Date().addingTimeInterval(TimeInterval(-2_000_000))))
            .environmentObject(GamesData(data: [getPlayedGame(), getPlayedGame(), getPlayedGame()]))
            .environmentObject(teams)
            .environmentObject(Settings())
            .environmentObject(getPickemData())
            .environmentObject(starredTeams)
            .environmentObject(getStandingsData())
            .environment(\.locale, .init(identifier: "sv"))
    }
}


struct GamesStatsView_No_Events_Previews: PreviewProvider {
    static var previews: some View {
        let teams = getTeamsData()
        
        let starredTeams = StarredTeams()
        starredTeams.addTeam(teamCode: "LHF")
        return GamesStatsView(details: GameDetails(game: getLiveGame(), events: [], stats: nil, players: []),
                              provider: nil,
                              game: getLiveGame())
            .environmentObject(GamesData(data: [getPlayedGame(), getPlayedGame(), getPlayedGame()]))
            .environmentObject(teams)
            .environmentObject(Settings())
            .environmentObject(getPickemData())
            .environmentObject(starredTeams)
            .environmentObject(getStandingsData())
            .environment(\.locale, .init(identifier: "sv"))
    }
}


struct GamesStatsView_Future_Game_Previews: PreviewProvider {
    static var previews: some View {
        let teams = getTeamsData()
        
        let starred = StarredTeams()
        starred.addTeam(teamCode: "LHF")
        return GamesStatsView(details: GameDetails(game: getFutureGame(), events: [], stats: nil, players: []),
                              provider: nil,
                              game: getFutureGame())
            .environmentObject(GamesData(data: [getPlayedGame(), getPlayedGame(), getPlayedGame()]))
            .environmentObject(teams)
            .environmentObject(Settings())
            .environmentObject(getPickemData())
            .environmentObject(starred)
            .environmentObject(getStandingsData())
            .environment(\.locale, .init(identifier: "sv"))
    }
}

struct GamesStatsView_Future_No_Prev_Game_Previews: PreviewProvider {
    static var previews: some View {
        let teams = getTeamsData()
        
        return GamesStatsView(details: GameDetails(game: getFutureGame(), events: [], stats: nil, players: []),
                              provider: nil,
                              game: getFutureGame())
            .environmentObject(GamesData(data: []))
            .environmentObject(teams)
            .environmentObject(Settings())
            .environmentObject(getPickemData())
            .environmentObject(getStandingsData())
            .environmentObject(StarredTeams())
            .environment(\.locale, .init(identifier: "sv"))
    }
}
struct PickemSliderViewPreviews: PreviewProvider {
    static var previews: some View {
        let teams = getTeamsData()
        
        return VStack {
            Spacer()
            PickemSliderView(game: getFutureGame(), onVote: { vote in
                
            })
            Spacer()
        }
        .padding()
        .background(Color(uiColor: .systemGroupedBackground))
            .environmentObject(GamesData(data: []))
            .environmentObject(teams)
            .environmentObject(Settings())
            .environmentObject(getPickemData())
            .environmentObject(getStandingsData())
            .environmentObject(StarredTeams())
            .environment(\.locale, .init(identifier: "sv"))
    }
}
