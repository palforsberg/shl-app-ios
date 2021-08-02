//
//  StarredTeams.swift
//  HockeyPal
//
//  Created by Pål Forsberg on 2021-01-14.
//

import Foundation


class StarredTeams: ObservableObject {
    var starredTeams: [String] {
        didSet {
            storage.setValue(starredTeams, forKey: "starredTeams")
            storage.synchronize()
        }
    }
    
    private var storage = UserDefaults.standard
    
    init() {
        starredTeams = storage.array(forKey: "starredTeams") as? [String] ?? []
    }

    func isStarred(teamCode: String) -> Bool {
        return starredTeams.contains(teamCode)
    }

    func addTeam(teamCode: String) {
        guard !isStarred(teamCode: teamCode) else {
            return
        }
        
        starredTeams.append(teamCode)
        self.objectWillChange.send()
    }

    func removeTeam(teamCode: String) {
        guard isStarred(teamCode: teamCode) else {
            return
        }
        starredTeams.removeAll(where: { $0 == teamCode })
        self.objectWillChange.send()
    }
}
