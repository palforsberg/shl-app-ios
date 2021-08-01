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
    var title: String?
    var content: () -> Content
    
    var body: some View {
        VStack {
            if let t = title {
                Text(LocalizedStringKey(t)).listHeader()
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
    let title: String
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

struct GamesStatsView: View {
    @State var gameStats: GameStats?
    @State var previousGames: [Game] = []
    @State var prevHomeWins: Int = 0
    @State var prevHomeLoss: Int = 0
    @State var prevHomeTies: Int = 0
    @EnvironmentObject var gamesData: GamesData
    @EnvironmentObject var teamsData: TeamsData
    
    var provider: DataProvider? = DataProvider()
    var game: Game
    
    var body: some View {
            ScrollView {
                Spacer(minLength: 25)
                Text("Swedish Hockey League").fontWeight(.medium)
                HStack(alignment: .center, spacing: 0) {
                    VStack {
                        TeamLogo(code: game.home_team_code, size: LogoSize.big)
                        Text(teamsData.getName(game.home_team_code))
                            .font(.system(size: 15, design: .rounded))
                            .fontWeight(.medium)
                    }.frame(width: /*@START_MENU_TOKEN@*/100/*@END_MENU_TOKEN@*/, height: 80).frame(maxWidth: 140)
            
                    HStack(alignment: .center, spacing: 15) {
                        Text("\(game.home_team_result)").font(.system(size: 40, design: .rounded)).fontWeight(.semibold)
                        Text("vs").font(.system(size: 20, design: .rounded)).padding(.top, 5)
                        Text("\(game.away_team_result)").font(.system(size: 40, design: .rounded)).fontWeight(.semibold)
                    }.padding(EdgeInsets(top: 0, leading: 5, bottom: 0, trailing: 5))
                    
                    VStack {
                        TeamLogo(code: game.away_team_code, size: LogoSize.big)
                        Text(teamsData.getName(game.away_team_code))
                            .font(.system(size: 15, design: .rounded))
                            .fontWeight(.medium)
                    }.frame(width: /*@START_MENU_TOKEN@*/100/*@END_MENU_TOKEN@*/, height: 80).frame(maxWidth: 140)
                }
                Spacer(minLength: 40)
                PeriodStatsView(title: "Match Detail", stats: gameStats?.recaps.gameRecap)
                Spacer(minLength: 40)
                Group {
                    if let period = gameStats?.recaps.period1 {
                        PeriodStatsView(title: "Period 1", stats: period)
                        Spacer(minLength: 20)
                    }
                    if let period = gameStats?.recaps.period2 {
                        PeriodStatsView(title: "Period 2", stats: period)
                        Spacer(minLength: 20)
                    }
                    if let period = gameStats?.recaps.period3 {
                        PeriodStatsView(title: "Period 3", stats: period)
                        Spacer(minLength: 40)
                    }
                    if let period = gameStats?.recaps.period4 {
                        PeriodStatsView(title: "Period 4", stats: period)
                        Spacer(minLength: 40)
                    }
                    if let period = gameStats?.recaps.period5 {
                        PeriodStatsView(title: "Period 5", stats: period)
                        Spacer(minLength: 40)
                    }
                }
                if (!previousGames.isEmpty) {
                    Text("Match History")
                        .font(.system(size: 18, design: .rounded))
                        .fontWeight(.semibold)
                        .foregroundColor(Color(UIColor.secondaryLabel))
                        .textCase(.uppercase)
                    HStack(spacing: 15) {
                        VStack {
                            Text("\(self.prevHomeWins)").font(.system(size: 20, design: .rounded)).fontWeight(.semibold)
                            Text("Wins").font(.system(size: 15, design: .rounded))
                        }.frame(maxWidth: 50)
                        Divider()
                        VStack {
                            Text("\(self.prevHomeTies)").font(.system(size: 20, design: .rounded)).fontWeight(.semibold)
                            Text("Ties").font(.system(size: 15, design: .rounded))
                        }.frame(maxWidth: 50)
                        Divider()
                        VStack {
                            Text("\(self.prevHomeLoss)").font(.system(size: 20, design: .rounded)).fontWeight(.semibold)
                            Text("Wins").font(.system(size: 15, design: .rounded))
                        }.frame(maxWidth: 50)
                    }
                    Spacer(minLength: 40)
                    GroupedView(title: "Played") {
                        ForEach(previousGames) { (item) in
                            NavigationLink(destination: GamesStatsView(game: item)) {
                                PlayedGame(game: item)
                            }.padding(EdgeInsets(top: 5, leading: 10, bottom: 5, trailing: 10))
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    Spacer(minLength: 40)
                }
            }
            .onAppear(perform: {
                provider?.getGameStats(game: game) { stats in
                    self.gameStats = stats
                }
                
                let allPrevGames = self.gamesData.getGamesBetween(team1: game.home_team_code, team2: game.away_team_code)
                self.previousGames = Array(allPrevGames.prefix(5))
                self.prevHomeWins = allPrevGames.filter({ $0.didWin(game.home_team_code) }).count
                self.prevHomeLoss = allPrevGames.filter({ !$0.didWin(game.home_team_code) }).count
                self.prevHomeTies = allPrevGames.filter({ $0.home_team_result == $0.away_team_result }).count
                    
            })
            .navigationBarTitle("", displayMode: .inline)
            .background(Color(UIColor.systemGroupedBackground))
    }
}

struct GamesStatsView_Previews: PreviewProvider {
    static var previews: some View {
        let teams = TeamsData()
        teams.setTeams(teams: [
            Team(code: "LHF", name: "Luleå HF"),
            Team(code: "FHC", name: "Frölunda HC")
        ])
        let allPeriods = AllPeriods(gameRecap: getPeriod(),
                                    period1: getPeriod(),
                                    period2: getPeriod(),
                                    period3: getPeriod()
        )
        
        return GamesStatsView(gameStats: GameStats(recaps: allPeriods, gameState: "Ended"),
                              provider: nil,
                              game: getLiveGame())
            .environmentObject(GamesData(data: [getPlayedGame(), getPlayedGame(), getPlayedGame()]))
            .environmentObject(teams)
            .environment(\.locale, .init(identifier: "sv"))
    }
    
    static func getPeriod() -> Period {
        return Period(periodNumber: 0, homeG: 3, awayG: 0, homeHits: 14, homeSOG: 64, homePIM: 654, homeFOW: 55, awayHits: 53, awaySOG: 23, awayPIM: 23, awayFOW: 0)
    }
}
