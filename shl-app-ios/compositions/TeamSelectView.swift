//
//  StarredTeamSelectView.swift
//  shl-app-ios
//
//  Created by Pål on 2023-03-17.
//

import SwiftUI

struct TeamSelectView: View {
    
    @EnvironmentObject var starredTeams: StarredTeams
    @EnvironmentObject var teams: TeamsData
    
    @Binding var selectedTeams: [String]
    
    var description = "Select teams to search for"
    
    var body: some View {
        List {
            Section {
                HStack(spacing: 0) {
                    ForEach(self.selectedTeams, id: \.self) { code in
                        TeamLogo(code: code)
                    }
                }
                Text(self.description)
            }
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)
            Section(header: Text("Swedish Hockey League").rounded(size: 20, weight: .semibold)) {
                Button {
                    self.toggleAllFrom(league: .shl)
                    
                } label: {
                    HStack {
                        Text("All in SHL")
                        if teams.getTeams(.shl).map(\.code).allSatisfy({ a in selectedTeams.contains(a)}) {
                            Spacer()
                            Image(systemName: "checkmark")
                                .transition(.scale)
                                .foregroundColor(Color(uiColor: .label))
                                .font(.system(size: 18, weight: .heavy, design: .rounded))
                                .padding(.trailing, 10)
                        }
                    }
                }
                    .padding(EdgeInsets(top: 8, leading: 0, bottom: 8, trailing: 0))
                ForEach(values: self.teams.getTeams(.shl).sorted(by: { a, b in a.shortname < b.shortname })) { a in
                    Button {
                        self.toggleTeam(code: a.code)
                    } label: {
                        HStack {
                            TeamLogo(code: a.code)
                            Text(a.name)
                                .starred(starredTeams.isStarred(teamCode: a.code), height: 2)
                            if selectedTeams.contains(a.code) {
                                Spacer()
                                Image(systemName: "checkmark")
                                    .transition(.scale)
                                    .foregroundColor(Color(uiColor: .label))
                                    .font(.system(size: 18, weight: .heavy, design: .rounded))
                                    .padding(.trailing, 10)
                            }
                        }
                    }
                    .padding(EdgeInsets(top: 6, leading: 0, bottom: 6, trailing: 0))
                    
                    
                }
            }
            Section(header: Text("Hockey Allsvenskan").rounded(size: 20, weight: .semibold)) {
                Button {
                    self.toggleAllFrom(league: .ha)
                    
                } label: {
                    HStack {
                        Text("All in HA")
                        if teams.getTeams(.ha).map(\.code).allSatisfy({ a in selectedTeams.contains(a)}) {
                            Spacer()
                            Image(systemName: "checkmark")
                                .transition(.scale)
                                .foregroundColor(Color(uiColor: .label))
                                .font(.system(size: 18, weight: .heavy, design: .rounded))
                                .padding(.trailing, 10)
                        }
                    }
                }
                    .padding(EdgeInsets(top: 8, leading: 0, bottom: 8, trailing: 0))
                ForEach(values: self.teams.getTeams(.ha).sorted(by: { a, b in a.shortname < b.shortname })) { a in
                    Button {
                        self.toggleTeam(code: a.code)
                    } label: {
                        HStack {
                            TeamLogo(code: a.code)
                            Text(a.name).starred(starredTeams.isStarred(teamCode: a.code), height: 2)
                            if selectedTeams.contains(a.code) {
                                Spacer()
                                Image(systemName: "checkmark")
                                    .transition(.scale)
                                    .foregroundColor(Color(uiColor: .label))
                                    .font(.system(size: 18, weight: .heavy, design: .rounded))
                                    .padding(.trailing, 10)
                            }
                        }
                    }
                    .padding(EdgeInsets(top: 8, leading: 0, bottom: 8, trailing: 0))
                }
            }
        }.font(.system(size: 18, weight: .bold, design: .rounded))
            .accentColor(Color(uiColor: .label))

    }
    
    func toggleTeam(code: String) {
        if self.selectedTeams.contains(code) {
            self.selectedTeams.removeAll(where: {e in e == code })
        } else {
            self.selectedTeams.append(code)
        }
    }
    
    func toggleAllFrom(league: League) {
        let all_teams = teams.getTeams(league).map({ $0.code })
        if all_teams.allSatisfy({ a in selectedTeams.contains(a)}) {
            all_teams.forEach { code in selectedTeams.removeAll(where: { $0 == code }) }
        } else {
            all_teams.forEach { code in
                if !selectedTeams.contains(code) {
                    selectedTeams.append(code)
                }
            }
        }
    }
}


struct TeamSelectViewWrapper: View {
    @State  var selectedTeams: [String] = ["IFB", "TIK", "SAIK"]
    
    var body: some View {
        TeamSelectView(selectedTeams: $selectedTeams)
    }
}
struct TeamSelectView_Previews: PreviewProvider {
    static var previews: some View {
        TeamSelectViewWrapper()
            .environmentObject(StarredTeams())
            .environmentObject(getTeamsData())
        
    }
}
