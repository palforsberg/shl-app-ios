//
//  StandingsView.swift
//  HockeyPal
//
//  Created by Pål Forsberg on 2021-01-08.
//

import SwiftUI

struct StandingsView: View {
    @State var standings = [Standing]()
    @EnvironmentObject var teams: Teams
    
    var body: some View {
        NavigationView {
            List(standings) { item in
                let team = teams.getTeam(item.team_code)
                NavigationLink(destination: TeamView(teamCode: item.team_code)) {
                    HStack() {
                        Text("#\(item.rank)")
                            .font(.subheadline)
                            .fontWeight(.bold)
                            .frame(width: 30, height: 20)
                            .foregroundColor(Color.gray)
                        TeamLogo(code: item.team_code)
                        Text(team?.name ?? item.team_code)
                            .font(.headline)
                            .fontWeight(.medium)
                        Spacer()
                        PointsText("\(item.gp)")
    //                    PointsText(String(format: "%.2f", item.getPointsPerGame()))
                        PointsText("\(item.points)")
                            .padding(.trailing, 5.0)
                    }.padding(EdgeInsets(top: 10, leading: 0, bottom: 10, trailing: 0))
                }.buttonStyle(PlainButtonStyle())
            }
            .listStyle(InsetGroupedListStyle())
            .navigationBarTitle(Text("SHL"))
            .onAppear(perform: {
                getStandings { (result) in
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
            .font(.system(size: 14))
            .fontWeight(.medium)
            .frame(width: 30, height: 20)
            .multilineTextAlignment(.trailing)
    }
}

struct StandingsView_Previews: PreviewProvider {
    static var previews: some View {
        StandingsView()
    }
}
