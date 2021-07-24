//
//  StarredTeams.swift
//  HockeyPal
//
//  Created by Pål Forsberg on 2021-01-14.
//

import Foundation


class StarredTeams: ObservableObject {
    @Published var starredTeams: [String] {
        didSet {
            storage.setValue(starredTeams, forKey: "starredTeams")
            storage.synchronize()
        }
    }
    
    var storage = UserDefaults.standard
    
    init() {
        starredTeams = storage.array(forKey: "starredTeams") as? [String] ?? [String]()
    }

    func get() -> [String] {
        return starredTeams
    }

    func isStarred(teamCode: String) -> Bool {
        return starredTeams.contains(teamCode)
    }

    func addTeam(teamCode: String) {
        guard !isStarred(teamCode: teamCode) else {
            return
        }
        
        starredTeams.append(teamCode)
    }

    func removeTeam(teamCode: String) {
        guard isStarred(teamCode: teamCode) else {
            return
        }
        
        starredTeams.removeAll(where: { (e) -> Bool in
            return e == teamCode
        })
    }
}
