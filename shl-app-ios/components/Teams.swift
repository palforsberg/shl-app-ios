//
//  Teams.swift
//  HockeyPal
//
//  Created by Pål Forsberg on 2021-01-14.
//

import Foundation


class Teams: ObservableObject {
    
    @Published var teams = [String:Team]()
    
    func getTeam(_ code: String) -> Team? {
        return teams[code]
    }

    func fetch() {
        getData(url: teamsUrl, type: TeamsData.self) { (t) in
            for team in t.data {
                self.teams[team.code] = team
            }
        }
    }
}
