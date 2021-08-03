//
//  StandingsView.swift
//  HockeyPal
//
//  Created by Pål Forsberg on 2021-01-08.
//

import SwiftUI

struct StandingsView: View {
    @EnvironmentObject var standings: StandingsData
    @EnvironmentObject var teams: TeamsData
    @EnvironmentObject var starredTeams: StarredTeams
    @EnvironmentObject var season: Season

    var provider: DataProvider?
    
    var body: some View {
        NavigationView {
            List {
                Section(header: Text("Season_param \(season.getFormatted())").listHeader()) {
                    ForEach(standings.get()) { item in
                        NavigationLink(destination: TeamView(teamCode: item.team_code, standing: item)) {
                            HStack() {
                                Text("#\(item.rank)")
                                    .font(.system(size: 16, design: .rounded))
                                    .fontWeight(.semibold)
                                    .points()
                                    .frame(width: 30)
                                    .foregroundColor(Color.gray)
                                TeamAvatar(item.team_code)
                                Image(systemName: "star.circle.fill")
                                    .foregroundColor(starredTeams.isStarred(teamCode: item.team_code) ? Color(UIColor.systemYellow) : Color.clear)
                                    .frame(width: 10)
                                    .padding(.leading, -10)
                                Text("\(item.gp)").points()
                                Text("\(item.points)").points()
                            }.padding(EdgeInsets(top: 10, leading: 0, bottom: 10, trailing: 0))
                        }.buttonStyle(PlainButtonStyle())
                    }
                }
            }
            .id(UUID()) // makes sure list is recreated when rerendered. To take care of reuse cell issues
            .listStyle(InsetGroupedListStyle())
            .navigationBarTitle(Text("SHL"))
            .onAppear(perform: {
            })
            .navigationBarItems(trailing: NavigationLink(destination: SettingsView()) {
                Image(systemName: "gear")
            })
        }.onReceive(season.$season, perform: { _ in
            provider?.getStandings(season: season.season) { (result) in
                self.standings.set(data: result)
            }
        })
    }
}

struct StandingsView_Previews: PreviewProvider {
    static var previews: some View {
        let starredTeams = StarredTeams()
        starredTeams.addTeam(teamCode: "SAIK")
        
        let standingsData = StandingsData(data: [getStanding("LHF", rank: 1, gp: 99, points: 999), getStanding("SAIK", rank: 14)])
        return StandingsView(provider: nil)
            .environmentObject(TeamsData())
            .environmentObject(starredTeams)
            .environmentObject(standingsData)
            .environmentObject(Season())
            .environment(\.locale, .init(identifier: "sv"))
    }
}
