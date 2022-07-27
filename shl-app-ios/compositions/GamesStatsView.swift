//
//  GamesStatsView.swift
//  shl-app-ios
//
//  Created by Pål on 2021-07-28.
//

import SwiftUI


struct StatsRow: View {
    var left: String
    var center: String
    var right: String
    
    var body: some View {
        HStack() {
            Text(left).font(.system(size: 20, design: .rounded)).fontWeight(.bold).frame(width: 45, alignment: .leading)
            Spacer()
            Text(LocalizedStringKey(center)).font(.system(size: 18, design: .rounded)).fontWeight(.semibold).frame(maxWidth: .infinity, alignment: .center)
            Spacer()
            Text(right).font(.system(size: 20, design: .rounded)).fontWeight(.bold).frame(width: 45, alignment: .trailing)
        }.padding(EdgeInsets(top: 3, leading: 0, bottom: 3, trailing: 0))
    }
}

struct GroupedView<Content: View>: View {
    var title: LocalizedStringKey?
    var content: () -> Content
    
    var body: some View {
        VStack {
            if let t = title {
                Text(t).listHeader()
                    .padding(.bottom, -4)
            }
            ZStack {
                RoundedRectangle(cornerRadius: 10.0).foregroundColor(Color(UIColor.secondarySystemGroupedBackground))
                VStack {
                    content()
                }.padding(EdgeInsets(top: 10, leading: 10, bottom: 10, trailing: 10))
            }
        }.padding(EdgeInsets(top: 0, leading: 15, bottom: 0, trailing: 15))
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
            }.padding(EdgeInsets(top: 15, leading: 30, bottom: 15, trailing: 30))
        }
    }
}

struct MatchHistoryView: View {
    
    @EnvironmentObject var gamesData: GamesData
    
    @State var prevHomeWins: Int = 0
    @State var prevHomeLoss: Int = 0
    @State var prevHomeWinsOt: Int = 0
    @State var prevHomeLossOt: Int = 0
    
    var homeTeam: String
    var awayTeam: String
    
    var body: some View {
        Text("Match History").listHeader(false)
        HStack(spacing: 15) {
            VStack {
                Text("\(self.prevHomeWins)").font(.system(size: 20, design: .rounded)).fontWeight(.semibold)
                Text("Wins").font(.system(size: 15, design: .rounded))
            }
            Divider()
            VStack {
                Text("\(self.prevHomeWinsOt)").font(.system(size: 20, design: .rounded)).fontWeight(.semibold)
                Text("Wins OT").font(.system(size: 15, design: .rounded))
            }
            Divider()
            VStack {
                Text("\(self.prevHomeLossOt)").font(.system(size: 20, design: .rounded)).fontWeight(.semibold)
                Text("Wins OT").font(.system(size: 15, design: .rounded))
            }
            Divider()
            VStack {
                Text("\(self.prevHomeLoss)").font(.system(size: 20, design: .rounded)).fontWeight(.semibold)
                Text("Wins").font(.system(size: 15, design: .rounded))
            }
        }
        .onAppear {
            let allPrevGames = self.gamesData.getGamesBetween(team1: homeTeam, team2: awayTeam)
            self.prevHomeWins = allPrevGames.filter({ $0.didWin(homeTeam) && !$0.didFinishedInOt() }).count
            self.prevHomeWinsOt = allPrevGames.filter({ $0.didWin(homeTeam) && $0.didFinishedInOt() }).count
            self.prevHomeLoss = allPrevGames.filter({ !$0.didWin(homeTeam) && !$0.didFinishedInOt() }).count
            self.prevHomeLossOt = allPrevGames.filter({ !$0.didWin(homeTeam) && $0.didFinishedInOt() }).count
        }
    }
}

struct TopPlayerView: View {
    var player: Player
    var body: some View {
        VStack {
            HStack {
                TeamLogo(code: player.team, size: .mini)
                Text("\(player.firstName) \(player.familyName)").fontWeight(.semibold).font(.system(size: 16, design: .rounded))
                Spacer()
                Text("#\(player.jersey)").fontWeight(.semibold).font(.system(size: 15, design: .rounded))
            }.padding(.bottom, -4)
            HStack {
                Text("G \(player.g)").fontWeight(.semibold).font(.system(size: 14, design: .rounded)).opacity(player.g == 0 ? 0.4 : 1)
                Text("A \(player.a)").fontWeight(.semibold).font(.system(size: 14, design: .rounded)).opacity(player.a == 0 ? 0.4 : 1)
                Text("PIM \(player.pim)").fontWeight(.semibold).font(.system(size: 14, design: .rounded)).opacity(player.pim == 0 ? 0.4 : 1)
                Spacer()
                Text(player.toi).fontWeight(.semibold).font(.system(size: 14, design: .rounded))
            }.padding(.leading, 28)
        }
    }
}

struct GamesStatsView: View {
    @State var gameStats: GameStats?
    @State var previousGames: [Game] = []
    @State var topPlayers: [Player] = []
    @State var hasFetched = false

    @EnvironmentObject var gamesData: GamesData
    @EnvironmentObject var starredTeams: StarredTeams
    @EnvironmentObject var teamsData: TeamsData
    @EnvironmentObject var settings: Settings
    
    var provider: DataProvider? = DataProvider()
    var game: Game
    
    var body: some View {
            ScrollView {
                PullToRefresh(coordinateSpaceName: "game_stats_scrollview") {
                    self.reloadData()
                }
                Spacer(minLength: 10)
                Text("Swedish Hockey League").fontWeight(.semibold).font(.system(size: 15, design: .rounded))
                    .foregroundColor(Color(UIColor.secondaryLabel))
                Spacer(minLength: 0)
                Text(LocalizedStringKey(game.getGameType()?.rawValue ?? ""))
                    .fontWeight(.semibold).font(.system(size: 15, design: .rounded))
                    .foregroundColor(Color(UIColor.secondaryLabel))
                Spacer(minLength: 25)
                Group { // Header
                    HStack(alignment: .center, spacing: 0) {
                        VStack {
                            TeamLogo(code: game.home_team_code, size: LogoSize.big)
                            Text(teamsData.getName(game.home_team_code))
                                .font(.system(size: 15, design: .rounded))
                                .fontWeight(.medium)
                                .starred(starredTeams.isStarred(teamCode: game.home_team_code))
                                .scaledToFit()
                                .minimumScaleFactor(0.8)
                                
                        }.frame(width: /*@START_MENU_TOKEN@*/100/*@END_MENU_TOKEN@*/, height: 80).frame(maxWidth: 140)
                
                        HStack(alignment: .center, spacing: 15) {
                            Text("\(gameStats?.recaps.gameRecap?.homeG ?? game.home_team_result)").font(.system(size: 40, design: .rounded)).fontWeight(.semibold)
                            Text("vs").font(.system(size: 20, design: .rounded)).padding(.top, 5)
                            Text("\(gameStats?.recaps.gameRecap?.awayG ?? game.away_team_result)").font(.system(size: 40, design: .rounded)).fontWeight(.semibold)
                        }.padding(EdgeInsets(top: 0, leading: 5, bottom: 0, trailing: 5))
                        
                        VStack {
                            TeamLogo(code: game.away_team_code, size: LogoSize.big)
                            Text(teamsData.getName(game.away_team_code))
                                .font(.system(size: 15, design: .rounded))
                                .fontWeight(.medium)
                                .starred(starredTeams.isStarred(teamCode: game.away_team_code))
                                .scaledToFit()
                                .minimumScaleFactor(0.8)

                        }.frame(width: /*@START_MENU_TOKEN@*/100/*@END_MENU_TOKEN@*/, height: 80).frame(maxWidth: 140)
                    }.frame(maxWidth: .infinity)
                }
                if (game.isFuture()) {
                    Spacer(minLength: 20)
                    Text("Starts In").listHeader(false)
                    TimerView(referenceDate: game.start_date_time)
                    Spacer(minLength: 40)
                } else if let periodString = gameStats?.getPeriodNr() {
                    Text(LocalizedStringKey(periodString)).font(.system(size: 18, design: .rounded)).fontWeight(.semibold)
                    Spacer(minLength: 20)
                }

                if let period = gameStats?.recaps.gameRecap {
                    PeriodStatsView(title: "Match Detail", stats: period)
                    Spacer(minLength: 30)
                }
                if hasFetched { // hide until all data has been fetched to avoid jumping UI
                    if !topPlayers.isEmpty {
                        Group {
                            ForEach(topPlayers) { p in
                                TopPlayerView(player: p)
                            }
                        }.padding(EdgeInsets(top: 7, leading: 40, bottom: 8, trailing: 45))
                        Spacer(minLength: 30)
                    }
                    MatchHistoryView(homeTeam: game.home_team_code, awayTeam: game.away_team_code)
                    Spacer(minLength: 40)
                    if (!previousGames.isEmpty) {
                        GroupedView(title: "Played_param \(settings.getFormattedPrevSeason())") {
                            ForEach(previousGames) { (item) in
                                NavigationLink(destination: GamesStatsView(game: item)) {
                                    PlayedGame(game: item)
                                }.buttonStyle(PlainButtonStyle())
                                if (item != previousGames.last) {
                                    Divider()
                                }
                            }
                        }
                        Spacer(minLength: 40)
                    }
                }
            }
            .onAppear(perform: {
                self.reloadData()
                let allPrevGames = self.gamesData.getGamesBetween(team1: game.home_team_code, team2: game.away_team_code)
                self.previousGames = allPrevGames.filter({ $0.game_uuid != game.game_uuid })
                    
            })
            .navigationBarTitle("", displayMode: .inline)
            .background(Color(UIColor.systemGroupedBackground))
            .coordinateSpace(name: "game_stats_scrollview")
    }
    
    func reloadData() {
        provider?.getGameStats(game: game) { stats in
            self.gameStats = stats
            self.topPlayers = stats.getTopPlayers()
            self.hasFetched = true
        }
        if provider == nil {
            self.topPlayers = self.gameStats?.getTopPlayers() ?? []
            self.hasFetched = true
        }
    }
}

struct GamesStatsView_Previews: PreviewProvider {
    static var previews: some View {
        let teams = TeamsData()
        teams.setTeams(teams: [
            Team(code: "LHF", name: "Luleå HF"),
            Team(code: "FBK", name: "Färjestad BK"),
            Team(code: "FHC", name: "Frölunda HC")
        ])
        let allPeriods = AllPeriods(gameRecap: getPeriod(),
                                    period1: getPeriod(),
                                    period2: getPeriod(),
                                    period3: getPeriod()
        )
        
        let starredTeams = StarredTeams()
        starredTeams.addTeam(teamCode: "LHF")
        return GamesStatsView(gameStats: GameStats(recaps: allPeriods, gameState: "Ongoing", playersByTeam: getPlayers()),
                              provider: nil,
                              game: getLiveGame())
            .environmentObject(GamesData(data: [getPlayedGame(), getPlayedGame(), getPlayedGame()]))
            .environmentObject(teams)
            .environmentObject(Settings())
            .environmentObject(starredTeams)
            .environment(\.locale, .init(identifier: "sv"))
    }
    
    static func getPeriod() -> Period {
        return Period(periodNumber: 0, homeG: 3, awayG: 0, homeHits: 14, homeSOG: 64, homePIM: 654, homeFOW: 55, awayHits: 53, awaySOG: 23, awayPIM: 23, awayFOW: 0)
    }
}

struct GamesStatsView_Future_Game_Previews: PreviewProvider {
    static var previews: some View {
        let teams = TeamsData()
        teams.setTeams(teams: [
            Team(code: "LHF", name: "Luleå HF"),
            Team(code: "FBK", name: "Färjestad BK"),
            Team(code: "FHC", name: "Frölunda HC")
        ])
        
        return GamesStatsView(gameStats: GameStats(recaps: AllPeriods(), gameState: "", playersByTeam: getPlayersWithZeroScore()),
                              provider: nil,
                              game: getFutureGame())
            .environmentObject(GamesData(data: [getPlayedGame(), getPlayedGame(), getPlayedGame()]))
            .environmentObject(teams)
            .environmentObject(Settings())
            .environmentObject(StarredTeams())
            .environment(\.locale, .init(identifier: "sv"))
    }
    
    static func getPeriod() -> Period {
        return Period(periodNumber: 0, homeG: 3, awayG: 0, homeHits: 14, homeSOG: 64, homePIM: 654, homeFOW: 55, awayHits: 53, awaySOG: 23, awayPIM: 23, awayFOW: 0)
    }
}

struct GamesStatsView_Future_No_Prev_Game_Previews: PreviewProvider {
    static var previews: some View {
        let teams = TeamsData()
        teams.setTeams(teams: [
            Team(code: "LHF", name: "Luleå HF"),
            Team(code: "FBK", name: "Färjestad BK"),
            Team(code: "FHC", name: "Frölunda HC")
        ])
        let allPeriods = AllPeriods(gameRecap: nil)
        
        return GamesStatsView(gameStats: GameStats(recaps: allPeriods, gameState: "GameEnded", playersByTeam: getPlayersWithZeroScore()),
                              provider: nil,
                              game: getFutureGame())
            .environmentObject(GamesData(data: []))
            .environmentObject(teams)
            .environmentObject(Settings())
            .environmentObject(StarredTeams())
            .environment(\.locale, .init(identifier: "sv"))
    }
    
    static func getPeriod() -> Period {
        return Period(periodNumber: 0, homeG: 3, awayG: 0, homeHits: 14, homeSOG: 64, homePIM: 654, homeFOW: 55, awayHits: 53, awaySOG: 23, awayPIM: 23, awayFOW: 0)
    }
}
