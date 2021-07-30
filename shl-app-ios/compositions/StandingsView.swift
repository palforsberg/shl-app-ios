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
                NavigationLink(destination: TeamView(teamCode: item.team_code)) {
                    HStack() {
                        Text("#\(item.rank)")
                            .font(.subheadline)
                            .fontWeight(.bold)
                            .frame(width: 30, height: 20)
                            .foregroundColor(Color.gray)
                        TeamAvatar(item.team_code)
                        Spacer()
                        PointsText("\(item.gp)")
                        PointsText(String(format: "%.2f", item.getPointsPerGame()))
                        PointsText("\(item.points)")
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

struct PointsText: View {
    var points: String
    init(_ points: String) {
        self.points = points
    }

    var body: some View {
        Text("\(points)")
            .font(.system(size: 14, design: .rounded))
            .fontWeight(.medium)
            .frame(width: 30, height: 20)
            .multilineTextAlignment(.trailing)
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
