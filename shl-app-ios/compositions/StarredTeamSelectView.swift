//
//  StarredTeamSelectView.swift
//  shl-app-ios
//
//  Created by Pål on 2023-03-17.
//

import SwiftUI

struct StarredTeamSelectView: View {
    
    @EnvironmentObject var starredTeams: StarredTeams
    @EnvironmentObject var teams: TeamsData
    
    var body: some View {
        List {
            Section(header: Text("\(League.shl.rawValue)").listHeader(false)) {
                ForEach(values: self.teams.getTeams(.shl).sorted(by: { a, b in a.shortname < b.shortname })) { a in
                    Button(action: { starredTeams.toggleTeam(a.code) }) {
                        HStack {
                            let starred = self.starredTeams.isStarred(teamCode: a.code)
                            TeamLogo(code: a.code)
                            Text(a.name).starred(starred, height: 2)
                            if starred {
                                Spacer()
                                Image(systemName: "star.fill")
                                    .transition(.scale)
                                    .foregroundColor(.yellow)
                            }
                        }
                    }
                    .padding(.vertical, 6)
                    .font(.system(size: 16, weight: .heavy, design: .rounded))
                    .accentColor(Color(uiColor: .label))
                }
            }
            Section(header: Text("\(League.ha.rawValue)").listHeader(false)) {
                ForEach(values: self.teams.getTeams(.ha).sorted(by: { a, b in a.name < b.name })) { a in
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
                    .padding(.vertical, 6)
                    .font(.system(size: 16, weight: .heavy, design: .rounded))
                    .accentColor(Color(uiColor: .label))
                }
            }
        }
    }
}

struct StarredTeamSelectView_Previews: PreviewProvider {
    @State static var selectedTeams: [String] = ["IFB", "TIK", "SAIK"]
    static var previews: some View {
        let teams = getTeamsData()
        let starredTeams = StarredTeams()
        StarredTeamSelectView()
            .environmentObject(starredTeams)
            .environmentObject(teams)
        
    }
}
