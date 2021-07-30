//
//  GamesStatsView.swift
//  shl-app-ios
//
//  Created by Pål on 2021-07-28.
//

import SwiftUI

struct GamesStatsView: View {
    @State var gameStats: GameStats?
    @State var previousGames: [Game] = []
    @EnvironmentObject var gamesData: GamesData
    
    var game: Game
    
    var body: some View {
            ScrollView() {
                Text("Svenska Hockey Ligan").fontWeight(.medium)
                HStack {
                    VStack {
                        TeamLogo(code: game.home_team_code, size: LogoSize.big)
                        Text("Luleå HF")
                    }
                    Spacer()
                    Text("\(game.home_team_result)").font(.system(size: 40, design: .rounded))
                    Text("-").font(.system(size: 20, design: .rounded))
                    Text("\(game.away_team_result)").font(.system(size: 40, design: .rounded))
                    Spacer()
                    VStack {
                        TeamLogo(code: game.away_team_code, size: LogoSize.big)
                        Text("Frölunda HC")
                    }
                }.padding(EdgeInsets(top: 0, leading: 40, bottom: 0, trailing: 40))
                Section(header: Text("Match Detaljer").font(.headline), content: {
                    VStack(alignment: .leading) {
                        HStack() {
                            Text("\(gameStats?.getRecap().homeSOG ?? 0)")
                            Spacer()
                            Text("Skott")
                            Spacer()
                            Text("\(gameStats?.getRecap().awaySOG ?? 0)")
                        }.padding(EdgeInsets(top: 0, leading: 20, bottom: 0, trailing: 20))
                    }.padding(EdgeInsets(top: 10, leading: 0, bottom: 10, trailing: 0))
                    VStack(alignment: .leading) {
                        HStack() {
                            Text("\(gameStats?.getRecap().homePIM ?? 0)")
                            Spacer()
                            Text("PIM")
                            Spacer()
                            Text("\(gameStats?.getRecap().awayPIM ?? 0)")
                        }.padding(EdgeInsets(top: 0, leading: 20, bottom: 0, trailing: 20))
                    }.padding(EdgeInsets(top: 10, leading: 0, bottom: 10, trailing: 0))
                    VStack(alignment: .leading) {
                        HStack() {
                            Text("\(gameStats?.getRecap().homeFOW ?? 0)")
                            Spacer()
                            Text("FOW")
                            Spacer()
                            Text("\(gameStats?.getRecap().awayFOW ?? 0)")
                        }.padding(EdgeInsets(top: 0, leading: 20, bottom: 0, trailing: 20))
                    }.padding(EdgeInsets(top: 10, leading: 0, bottom: 10, trailing: 0))
                    VStack(alignment: .leading) {
                        HStack() {
                            Text("\(gameStats?.getRecap().homeHits ?? 0)")
                            Spacer()
                            Text("Hits")
                            Spacer()
                            Text("\(gameStats?.getRecap().awayHits ?? 0)")
                        }.padding(EdgeInsets(top: 0, leading: 20, bottom: 0, trailing: 20))
                    }.padding(EdgeInsets(top: 10, leading: 0, bottom: 10, trailing: 0))
                })
                List {
                    Section(header: Text("Played").font(.headline), content: {
                        ForEach(previousGames) { (item) in
                            NavigationLink(destination: GamesStatsView(game: item)) {
                                VStack(alignment: .leading) {
                                    PlayedGame(game: item)
                                }.padding(EdgeInsets(top: 10, leading: 0, bottom: 10, trailing: 0))
                            }
                        }
                    })
                }
            }.onAppear(perform: {
                DataProvider().getGameStats(game: game) { stats in
                    self.gameStats = stats.data
                }
                
                self.previousGames = self.gamesData.getGamesBetween(team1: game.home_team_code, team2: game.away_team_code)
            })
    }
}

struct GamesStatsView_Previews: PreviewProvider {
    static var previews: some View {
        GamesStatsView(game: getGame())
    }
    
    
    static func getGame() -> Game {
        return Game(game_id: 13558, game_uuid: "qZi-3RRn5CM5T", away_team_code: "FHC", away_team_result: 0, home_team_code: "LHF", home_team_result: 2, start_date_time: Date(), played: false)
    }
}
