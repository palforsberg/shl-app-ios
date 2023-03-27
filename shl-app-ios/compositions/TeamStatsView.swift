//
//  TeamStatsView.swift
//  shl-app-ios
//
//  Created by Pål on 2023-03-18.
//

import SwiftUI


extension Text {
    func mega(size: CGFloat = 50) -> some View {
        self.font(.system(size: size, weight: .black, design: .rounded))
            .gradientForeground(colors: [Color(uiColor: .secondaryLabel), Color(uiColor: .label), Color(uiColor: .secondaryLabel)])
            .minimumScaleFactor(0.8)
    }
    func mini(size: CGFloat = 15) -> some View {
        self.font(.system(size: size, weight: .bold, design: .rounded))
            .foregroundColor(Color(uiColor: .secondaryLabel))
    }
}

extension View {
    public func gradientForeground(colors: [Color]) -> some View {
        self.overlay(LinearGradient(
            colors: colors,
            startPoint: .topLeading,
            endPoint: .bottomTrailing))
        .mask(self)
    }
}

struct Box<Content: View>: View {
    @ViewBuilder var content: () -> Content
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(uiColor: .secondarySystemGroupedBackground))
                .shadow(color: Color(uiColor: .systemGray4), radius: 3, x: 0, y: 2)
            VStack(alignment: .center) {
                content()
            }.padding(EdgeInsets(top: 10, leading: 10, bottom: 10, trailing: 10))
        }
    }
}
struct TeamStatsView: View {
    
    @EnvironmentObject var starredTeams: StarredTeams
    @EnvironmentObject var teams: TeamsData
    @EnvironmentObject var games: GamesData
    
    let columns = [
        GridItem(.adaptive(minimum: 100)),
        GridItem(.adaptive(minimum: 100))
    ]
    
    var teamCode: String
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                HStack(spacing: 20) {
                    Box {
                        TeamLogo(code: teamCode, size: 100)
                        Text(teams.getName(teamCode))
                    }
                    Box {
                        Text("Spelade")
                        Text("56").mega()
                        Text("matcher")
                    }
                    
                }
                HStack(spacing: 20) {
                    FormGraph(teamCode: teamCode, numberOfGames: 100)
                }.padding(.top, 10).padding(.bottom, 10)
                HStack(spacing: 20) {
                    Box {
                        Text("6122").mega()
                        Text("mål")
                    }
                    
                    Box {
                        Text("5.6K").mega()
                        Text("straffminuter")
                    }
                }
                HStack(spacing: 20) {
                    Box {
                        Text("5x").mega()
                        Text("Vinststreak")
                    }
                    Box {
                        Text("3").mega()
                        Text("Hållna 0:or")
                    }
                }
                HStack(spacing: 20) {
                    Box {
                        Text("Störst vinst")
                        HStack(spacing: 30) {
                            TeamLogo(code: teamCode, size: 50)
                            Text("5 - 1").mega(size: 40)
                            TeamLogo(code: "MIF", size: 50)
                        }
                        Text("Januari 23")
                    }
                }
                
                HStack(spacing: 20) {
                    Box {
                        Text("Vinster hemma")
                        Text("45%").mega()
                    }
                    Box {
                        Text("Övertid")
                        Text("25").mega()
                        Text("matcher")
                    }
                }
                HStack(spacing: 20) {
                    Box {
                        Text("Favorit motståndare")
                        TeamLogo(code: "FHC", size: 80)
                        Text("Frölunda").mega(size: 30)
                        Text("5 vinster").mini()
                        Text("65 mål").mini()
                    }
                    Box {
                        Text("Värsta motståndare")
                        TeamLogo(code: "LHF", size: 80)
                        Text("Luleå").mega(size: 30)
                        Text("3 förluster").mini()
                        Text("65 insläppta mål").mini()
                    }
                }
                HStack(spacing: 20) {
                    Box {
                        Text("Bästa spelare")
                        PlayerImage(player: 2922, size: 80)
                        Text("Jonathan Dahlén").mega(size: 20)
                        Text("56 poäng")
                    }
                    
                    Box {
                        Text("Bästa passare")
                        PlayerImage(player: 999, size: 80)
                        Text("Anton Lander").mega(size: 20)
                        Text("56 assists")
                    }
                }
                HStack(spacing: 20) {
                    Box {
                        Text("Flitigast")
                        PlayerImage(player: 3808, size: 80)
                        Text("Johan Walli Walterholm").mega(size: 20)
                        Text("202 timmar istid")
                    }
                    Box {
                        Text("Fulspelaren")
                        PlayerImage(player: 3411, size: 80)
                        Text("Jakob Stenqvist").mega(size: 20)
                        Text("500 straffminuter")
                    }
                }
            }
            .padding(EdgeInsets(top: 0, leading: 20, bottom: 0, trailing: 20))
        }
        .background(Color(uiColor: .systemGroupedBackground))
        .font(.system(size: 20, weight: .heavy, design: .rounded))
        .multilineTextAlignment(.center)
        
    }
}

struct TeamStatsView_Previews: PreviewProvider {
    static var previews: some View {
        let teams = getTeamsData()
        let starred = StarredTeams()
        starred.addTeam(teamCode: "TIK")
        return TeamStatsView(teamCode: "TIK")
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
        }
}
