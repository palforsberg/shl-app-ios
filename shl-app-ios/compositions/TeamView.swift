//
//  TeamView.swift
//  HockeyPal
//
//  Created by Pål Forsberg on 2021-01-14.
//

import SwiftUI

struct TeamView: View {
    @EnvironmentObject var starredTeams: StarredTeams
    @EnvironmentObject var teams: Teams
    let teamCode: String
    
    var body: some View {
        let _team = self.teams.getTeam(teamCode)
        let starred = starredTeams.isStarred(teamCode: teamCode)
        if let team = _team {
            VStack(alignment: .center, spacing: 10, content: {
                Text("Svenska Hockey Ligan").fontWeight(.medium)
                TeamLogo(code: teamCode, size: .big)
                Text(team.name).font(.largeTitle).fontWeight(.medium)
                StarButton(starred: starred) {
                    if (starred) {
                        starredTeams.removeTeam(teamCode: teamCode)
                    } else {
                        starredTeams.addTeam(teamCode: teamCode)
                    }
                }
                Spacer()
            })
        }
    }
}

struct StarButton: View {
    var starred: Bool
    var action: () -> Void
    var body: some View {
        Button(action: action, label: {
            Image(systemName: starred ? "star.circle.fill" : "star.circle")
                .foregroundColor(.yellow)
            Text("Favourite").foregroundColor(.white)
        })
        .padding(6)
        .background(Color.gray)
        .cornerRadius(12)
        .buttonStyle(PlainButtonStyle())
    }
}

struct TeamView_Previews: PreviewProvider {
    static var previews: some View {
        let teams = Teams()
        teams.teams["LHF"] = Team(code: "LHF", name: "Luleå HF")
        return TeamView(teamCode: "LHF")
            .environmentObject(teams)
            .environmentObject(StarredTeams())
    }
}
