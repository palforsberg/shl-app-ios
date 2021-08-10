//
//  StandingsView.swift
//  HockeyPal
//
//  Created by Pål Forsberg on 2021-01-08.
//

import SwiftUI


extension Text {
    
    func points() -> some View {
        return self
            .font(.system(size: 15, design: .rounded))
            .fontWeight(.semibold)
    }
}

struct StandingsHeader: View {
    var season: String
    var body: some View {
        HStack {
            Text("Season_param \(season)").listHeader()
            Spacer()
            Text("GP").points()
                .frame(width: 34, alignment: .center)
            Text("P").points()
                .frame(width: 34, alignment: .center)
            Spacer(minLength: 34)
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
            Text(genZeros(nrZeros)).points().foregroundColor(Color(UIColor.tertiaryLabel))
            Text(str).foregroundColor(color).points()
        }
    }
    
    func genZeros(_ nr: Int) -> String {
        guard nr > 0 else {
            return ""
        }
        return String((0..<nr).map{ _ in "0" })
    }
}

struct StandingsView: View {
    @EnvironmentObject var standings: StandingsData
    @EnvironmentObject var teams: TeamsData
    @EnvironmentObject var starredTeams: StarredTeams
    @EnvironmentObject var settings: Settings

    var provider: DataProvider?
    
    var body: some View {
        NavigationView {
            List {
                Section(header: StandingsHeader(season: settings.getFormattedSeason())) {
                    ForEach(standings.get()) { item in
                        NavigationLink(destination: TeamView(teamCode: item.team_code, standing: item)) {
                            HStack() {
                                HStack(spacing: 0) {
                                    Text("#").foregroundColor(Color(UIColor.tertiaryLabel))
                                    PointsLabel(val: "\(item.rank)", nrDigits: 2, color: Color.secondary)
                                }
                                TeamAvatar(item.team_code)
                                Spacer()
                                PointsLabel(val: "\(item.gp)")
                                    .frame(width: 34, alignment: .center)
                                PointsLabel(val: "\(item.points)")
                                    .frame(width: 34, alignment: .center)
                            }.padding(EdgeInsets(top: 10, leading: 0, bottom: 10, trailing: 0))
                        }.buttonStyle(PlainButtonStyle())
                    }
                }
            }
            .id(UUID()) // makes sure list is recreated when rerendered. To take care of reuse cell issues
            .listStyle(InsetGroupedListStyle())
            .navigationBarTitle(Text("SHL"))
            .navigationBarItems(trailing: NavigationLink(destination: SettingsView()) {
                Image(systemName: "gear").frame(width: 44, height: 44, alignment: .trailing)
            })
        }.onReceive(settings.$season, perform: { _ in
            provider?.getStandings(season: settings.season) { (result) in
                self.standings.set(data: result)
            }
        })
    }
}

struct StandingsView_Previews: PreviewProvider {
    static var previews: some View {
        let starredTeams = StarredTeams()
        starredTeams.addTeam(teamCode: "SAIK")
        
        let standingsData = StandingsData(data: [
                                            getStanding("LHF", rank: 1, gp: 99, points: 999),
                                            getStanding("SAIK", rank: 14)])
        return StandingsView(provider: nil)
            .environmentObject(TeamsData())
            .environmentObject(starredTeams)
            .environmentObject(standingsData)
            .environmentObject(Settings())
            .environment(\.locale, .init(identifier: "sv"))
    }
}
