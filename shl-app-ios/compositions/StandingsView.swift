//
//  StandingsView.swift
//  HockeyPal
//
//  Created by Pål Forsberg on 2021-01-08.
//

import SwiftUI
import WidgetKit


extension Text {
    
    func points() -> some View {
        return self
            .font(.system(size: 15, weight: .heavy, design: .rounded))
    }
}

struct StandingsHeader: View {
    var season: String
    var body: some View {
        HStack {
            Text("Season_param \(season)").listHeader(true)
            Spacer()
            Text("GP").points()
                .frame(width: 34, alignment: .center)
                .foregroundColor(Color(uiColor: .secondaryLabel))
            Text("P").points()
                .frame(width: 34, alignment: .center)
                .foregroundColor(Color(uiColor: .secondaryLabel))
            Spacer(minLength: 17)
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
                .monospacedDigit()
            Text(str).foregroundColor(color).points()
                .monospacedDigit()
        }
    }
    
    func genZeros(_ nr: Int) -> String {
        guard nr > 0 else {
            return ""
        }
        return String((0..<nr).map{ _ in "0" })
    }
}

struct PlayoffEntryView: View {
    @EnvironmentObject var starredTeams: StarredTeams
    var entry: PlayoffEntry
    var mini: Bool = true
    
    var body: some View {
        VStack {
            HStack {
                TeamLogo(code: "\(entry.team1)", size: UIScreen.isMini ? 20 : 30)
                if !mini {
                    Text(entry.team1)
                        .starred(starredTeams.isStarred(teamCode: entry.team1))
                        .scaledToFit()
                        .minimumScaleFactor(0.6)
                        .frame(width: 45, alignment: .leading)
                }
                Text("\(entry.score1)").monospacedDigit()
            }.opacity(entry.team1 == "TBD" || entry.team1 == entry.eliminated ? 0.4 : 1.0)
            HStack {
                TeamLogo(code: "\(entry.team2)", size: UIScreen.isMini ? 20 : 30)
                if !mini {
                    Text(entry.team2)
                        .starred(starredTeams.isStarred(teamCode: entry.team1))
                        .scaledToFit()
                        .minimumScaleFactor(0.6)
                        .frame(width: 45, alignment: .leading)
                }
                Text("\(entry.score2)").monospacedDigit()
            }.opacity(entry.team2 == "TBD" || entry.team2 == entry.eliminated ? 0.4 : 1.0)
        }.font(.system(size: 18, weight: .heavy, design: .rounded))
            .padding(EdgeInsets(top: 15, leading: 15, bottom: 15, trailing: 15))
            .background(Color(uiColor: UIColor.secondarySystemGroupedBackground))
            .cornerRadius(20)
    }
}
struct PlayoffView: View {
    var playoff: Playoffs
    
    var body: some View {
        VStack(spacing: 10) {
            if let final = playoff.final {
                Text("FINAL")
                    .font(.system(size: 30, weight: .heavy, design: .rounded))
                    .foregroundColor(Color(uiColor: .secondaryLabel))
                HStack {
                    PlayoffEntryView(entry: final, mini: false)
                }
                Spacer(minLength: 10)
            }
            if let semis = playoff.semi {
                Text("Semifinal").listHeader()
                HStack {
                    ForEach(semis) { semi in
                        PlayoffEntryView(entry: semi, mini: false)
                    }
                }
                Spacer(minLength: 10)
            }
            if let quarters = playoff.quarter {
                Text("Quarterfinal").listHeader()
                HStack {
                    ForEach(quarters) { quart in
                        PlayoffEntryView(entry: quart, mini: true)
                    }
                }
                Spacer(minLength: 10)
            }
            if let eight = playoff.eight {
                Text("Eightfinal").listHeader()
                HStack {
                    ForEach(eight) {eigh in
                        PlayoffEntryView(entry: eigh, mini: false)
                    }
                }
                Spacer(minLength: 10)
            }
            
            if let entry = playoff.demotion {
                Text("Demotion").listHeader()
                PlayoffEntryView(entry: entry, mini: false)
                Spacer(minLength: 10)
            }
        }
    }
}
struct TeamEntry: View {
    @EnvironmentObject var starredTeams: StarredTeams
    var code: String
    
    var body: some View {
        TeamLogo(code: code)
        Text(code)
            .font(.system(size: 24, weight: .bold, design: .rounded))
            .starred(starredTeams.isStarred(teamCode: code))
    }
}
struct StandingsView: View {
    @EnvironmentObject var standings: StandingsData
    @EnvironmentObject var teams: TeamsData
    @EnvironmentObject var starredTeams: StarredTeams
    @EnvironmentObject var settings: Settings
    @EnvironmentObject var playoffs: PlayoffData

    var provider: DataProvider?
    
    var body: some View {
        NavigationView {
            ScrollView {
                if let po = self.playoffs.data {
                    PlayoffView(playoff: po)
                    Spacer(minLength: 10)
                } else {
                    Spacer(minLength: 20)
                }
                StandingsHeader(season: settings.getFormattedSeason())
                    .padding(EdgeInsets(top: 0, leading: 15, bottom: -2, trailing: 10))
                GroupedView(cornerRadius: 15) {
                    ForEach(standings.get(), id: \.team_code) { item in
                        NavigationLink(destination: TeamView(teamCode: item.team_code, standing: item)) {
                            VStack {
                                HStack() {
                                    HStack(spacing: 0) {
                                        Text("#").foregroundColor(Color(UIColor.tertiaryLabel))
                                        PointsLabel(val: "\(item.rank)", nrDigits: 2, color: Color.secondary)
                                    }
                                    TeamEntry(code: item.team_code)
                                    Spacer()
                                    PointsLabel(val: "\(item.gp)")
                                        .frame(width: 34, alignment: .center)
                                    PointsLabel(val: "\(item.points)")
                                        .frame(width: 34, alignment: .center)
                                    
                                }.padding(EdgeInsets(top: 20, leading: 10, bottom: item.team_code != standings.get().last?.team_code ? 15 : 25, trailing: 16))
                                if item.team_code != standings.get().last?.team_code {
                                    Divider()
                                }
                            }
                            .contentShape(Rectangle()) // Make sure whole row is clickable
                        }
                        .buttonStyle(ActiveButtonStyle())
                    }
                }
            }
            .refreshable {
                await self.reloadData()
            }
            .id(settings.season) // makes sure list is recreated when rerendered. To take care of reuse cell issues
            .navigationBarTitle(Text("SHL"))
            .background(Color(UIColor.systemGroupedBackground))
            .navigationBarItems(trailing: NavigationLink(destination: SettingsView()) {
                Image(systemName: "gearshape.circle").frame(width: 44, height: 44, alignment: .trailing)
            })
        }.onReceive(settings.$season, perform: { _ in
            Task {
                await self.reloadData()
            }
        })
    }
    
    func reloadData() async {
        async let standings = provider?.getStandings(season: settings.season, maxAge: 10)
        async let playoffs = provider?.getPlayoffs(maxAge: 10)
        
        let (result_standings, result_playoffs) = await (standings, playoffs)
        
        if let standings = result_standings?.entries {
            withAnimation {
                self.standings.set(data: standings)
            }
        }
        if result_standings?.type == .api {
            WidgetCenter.shared.reloadAllTimelines()
            debugPrint("[STANDINGS] reload widgets")
        }
        
        if let result = result_playoffs?.entries {
            self.playoffs.setData(result)
        }
    }
}


struct StandingsViewWithoutPlayoff_Previews: PreviewProvider {
    static var previews: some View {
        let starredTeams = StarredTeams()
        starredTeams.addTeam(teamCode: "SAIK")
        
        let standingsData = StandingsData(data: [
                                            getStanding("LHF", rank: 1, gp: 99, points: 999),
                                            getStanding("SAIK", rank: 2),
                                            getStanding("TIK", rank: 3),
                                            getStanding("VLH", rank: 4),
                                            getStanding("RBK", rank: 5),
                                            getStanding("LIF", rank: 6),
                                            getStanding("OHK", rank: 7),
                                            getStanding("FHC", rank: 8),
                                            getStanding("FBK", rank: 9),
                                            getStanding("MIF", rank: 10),
                                            getStanding("IKO", rank: 11),
                                            getStanding("LHC", rank: 12),
                                            getStanding("BIF", rank: 13),
                                            getStanding("HV71", rank: 14),
        ])
        let playoffs = PlayoffData()
        playoffs.setData(nil)
        return StandingsView(provider: nil)
            .environmentObject(TeamsData())
            .environmentObject(starredTeams)
            .environmentObject(standingsData)
            .environmentObject(Settings())
            .environmentObject(playoffs)
            .environment(\.locale, .init(identifier: "sv"))
    }
}


struct StandingsView_Previews: PreviewProvider {
    static var previews: some View {
        let starredTeams = StarredTeams()
        starredTeams.addTeam(teamCode: "SAIK")
        
        let standingsData = StandingsData(data: [
                                            getStanding("LHF", rank: 1, gp: 99, points: 999),
                                            getStanding("SAIK", rank: 2),
                                            getStanding("TIK", rank: 3),
                                            getStanding("VLH", rank: 4),
                                            getStanding("RBK", rank: 5),
                                            getStanding("LIF", rank: 6),
                                            getStanding("OHK", rank: 7),
                                            getStanding("FHC", rank: 8),
                                            getStanding("FBK", rank: 9),
                                            getStanding("MIF", rank: 10),
                                            getStanding("IKO", rank: 11),
                                            getStanding("LHC", rank: 12),
                                            getStanding("BIF", rank: 13),
                                            getStanding("HV71", rank: 14),
        ])
        let playoffs = PlayoffData()
        playoffs.setData(getPlayoffs())
        return StandingsView(provider: nil)
            .environmentObject(TeamsData())
            .environmentObject(starredTeams)
            .environmentObject(standingsData)
            .environmentObject(Settings())
            .environmentObject(playoffs)
            .environment(\.locale, .init(identifier: "sv"))
    }
}

struct PlayoffView_Previews: PreviewProvider {
    static var previews: some View {
        return ScrollView() {
            PlayoffView(playoff: getPlayoffs())
        }.background(Color(uiColor: .systemGroupedBackground))
    }
}
