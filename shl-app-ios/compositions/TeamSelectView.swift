//
//  TeamSelectView.swift
//  shl-app-ios
//
//  Created by Pål on 2023-03-17.
//

import SwiftUI

struct TeamSelectView: View {
    
    @EnvironmentObject var starredTeams: StarredTeams
    @EnvironmentObject var teams: TeamsData
    
    var body: some View {
        List {
            Section(header: Text("Swedish Hockey League").rounded(size: 20, weight: .semibold)) {
                ForEach(values: self.teams.teams.sorted(by: { a, b in a.name < b.name })) { a in
                    Button(action: { starredTeams.toggleTeam(a.code) }) {
                        HStack {
                            let starred = self.starredTeams.isStarred(teamCode: a.code)
                            TeamLogo(code: a.code)
                            Text(a.name)
                                .starred(starred, height: 2)
                            if starred {
                                Spacer()
                                Image(systemName: "star.fill")
                                    .transition(.scale)
                                    .foregroundColor(.yellow)
                            }
                        }
                    }
                    .padding(EdgeInsets(top: 8, leading: 0, bottom: 8, trailing: 0))
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                    .accentColor(Color(uiColor: .label))
                }
            }
        }
    }
}

struct TeamSelectView_Previews: PreviewProvider {
    static var previews: some View {
        let teams = getTeamsData()
        TeamSelectView()
            .environmentObject(StarredTeams())
            .environmentObject(teams)
    }
}
