//
//  StandingsView.swift
//  HockeyPal
//
//  Created by Pål Forsberg on 2021-01-08.
//

import SwiftUI

struct StandingsView: View {
    @State var standings = [Standing]()
    @EnvironmentObject var teams: TeamsData
    var provider: DataProvider? = DataProvider()
    
    var body: some View {
        NavigationView {
            List(standings) { item in
                NavigationLink(destination: TeamView(teamCode: item.team_code, standing: item)) {
                    HStack() {
                        Text("#\(item.rank)")
                            .points()
                            .frame(width: 30, height: 20)
                            .foregroundColor(Color.gray)
                        TeamAvatar(item.team_code)
                        Spacer()
                        Text("\(item.gp)").points()
                        Text(item.getPointsPerGame()).points()
                        Text("\(item.points)").points()
                    }.padding(EdgeInsets(top: 10, leading: 0, bottom: 10, trailing: 0))
                }.buttonStyle(PlainButtonStyle())
            }
            .listStyle(InsetGroupedListStyle())
            .navigationBarTitle(Text("SHL"))
            .onAppear(perform: {
                provider?.getStandings { (result) in
                    self.standings = result.data
                }
            })
            Color.gray
        }
    }
}

struct StandingsView_Previews: PreviewProvider {
    static var previews: some View {
        return StandingsView(standings: [getStanding()], provider: nil)
            .environmentObject(TeamsData())
    }
    static func getStanding() -> Standing {
        return Standing(team_code: "LHF", gp: 4, rank: 1, points: 3)
    }
}
