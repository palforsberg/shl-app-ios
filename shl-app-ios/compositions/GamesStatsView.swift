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
        }.padding(EdgeInsets(top: 5, leading: 0, bottom: 5, trailing: 0))
    }
}

struct GroupedView<Content: View>: View {
    var content: () -> Content
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10.0).foregroundColor(Color(UIColor.secondarySystemGroupedBackground))
            VStack {
                content()
            }.padding(EdgeInsets(top: 10, leading: 10, bottom: 10, trailing: 10))
        }.padding(EdgeInsets(top: 0, leading: 15, bottom: 0, trailing: 15))
    }
}

struct PeriodStatsView: View {
    let stats: Period?
    
    var body: some View {
        GroupedView {
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
    @EnvironmentObject var gamesData: GamesData
    
    var provider: DataProvider? = DataProvider()
    var game: Game
    
    var body: some View {
            ScrollView {
                Section(header: Text("Svenska Hockey Ligan").font(.headline)) {
                    HStack(alignment: .center, spacing: 0) {
                        VStack {
                            TeamLogo(code: game.home_team_code, size: LogoSize.big)
                            Text(game.home_team_code)
                        }.frame(width: /*@START_MENU_TOKEN@*/100/*@END_MENU_TOKEN@*/, height: 80).frame(maxWidth: 140)
                
                        HStack(alignment: .center, spacing: 15) {
                            Text("\(game.home_team_result)").font(.system(size: 40, design: .rounded))
                            Text("vs").font(.system(size: 20, design: .rounded)).padding(.top, 5)
                            Text("\(game.away_team_result)").font(.system(size: 40, design: .rounded))
                        }.padding(EdgeInsets(top: 0, leading: 5, bottom: 0, trailing: 5))
                        
                        VStack {
                            TeamLogo(code: game.away_team_code, size: LogoSize.big)
                            Text(game.away_team_code)
                        }.frame(width: /*@START_MENU_TOKEN@*/100/*@END_MENU_TOKEN@*/, height: 80).frame(maxWidth: 140)
                    }
                }
                Spacer(minLength: 40)
                Text("Match Detail").listHeader()
                PeriodStatsView(stats: gameStats?.recaps.gameRecap)
                Spacer(minLength: 40)
                if let period = gameStats?.recaps.period1 {
                    Text("Period 1").listHeader()
                    PeriodStatsView(stats: period)
                    Spacer(minLength: 40)
                }
                if let period = gameStats?.recaps.period2 {
                    Text("Period 2").listHeader()
                    PeriodStatsView(stats: period)
                    Spacer(minLength: 40)
                }
                if let period = gameStats?.recaps.period3 {
                    Text("Period 3").listHeader()
                    PeriodStatsView(stats: period)
                    Spacer(minLength: 40)
                }
                if (!previousGames.isEmpty) {
                    Text("Played").listHeader()
                    GroupedView {
                        ForEach(previousGames) { (item) in
                            NavigationLink(destination: GamesStatsView(game: item)) {
                                PlayedGame(game: item)
                            }.padding(EdgeInsets(top: 5, leading: 10, bottom: 5, trailing: 10))
                        }
                    }
                    Spacer(minLength: 40)
                }
            }
            .onAppear(perform: {
                provider?.getGameStats(game: game) { stats in
                    self.gameStats = stats
                }
                
                self.previousGames = Array(self.gamesData
                    .getGamesBetween(team1: game.home_team_code, team2: game.away_team_code)
                    .prefix(5))
                    
            })
            .background(Color(UIColor.systemGroupedBackground))
    }
}

struct GamesStatsView_Previews: PreviewProvider {
    static var previews: some View {
        GamesStatsView(gameStats: GameStats(recaps: AllPeriods(gameRecap: getPeriod()), gameState: "Ended"),
                       provider: nil,
                       game: getLiveGame())
            .environmentObject(GamesData(data: [getPlayedGame(), getPlayedGame(), getPlayedGame()]))
            .environment(\.locale, .init(identifier: "sv"))
    }
    
    static func getPeriod() -> Period {
        return Period(periodNumber: 0, homeG: 3, awayG: 0, homeHits: 14, homeSOG: 64, homePIM: 654, homeFOW: 55, awayHits: 53, awaySOG: 23, awayPIM: 23, awayFOW: 0)
    }
}
