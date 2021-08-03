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
            StarredTeams.storage.setValue(starredTeams, forKey: "starredTeams")
            StarredTeams.storage.synchronize()
        }
    }
    
    private static var storage = UserDefaults.standard
    private var debouncer: Debouncer?
    
    init() {
        self.starredTeams = StarredTeams.readFromDisk()
        self.debouncer = Debouncer({() in
            let apnToken = UserDefaults.standard.string(forKey: "apn_token")
            DataProvider().addUser(apnToken: apnToken, teams: self.starredTeams)
        }, seconds: 1)
    }

    func isStarred(teamCode: String) -> Bool {
        return starredTeams.contains(teamCode)
    }

    func addTeam(teamCode: String) {
        guard !isStarred(teamCode: teamCode) else {
            return
        }
        
        starredTeams.append(teamCode)
        didChangeTeams()
    }

    func removeTeam(teamCode: String) {
        guard isStarred(teamCode: teamCode) else {
            return
        }
        starredTeams.removeAll(where: { $0 == teamCode })
        didChangeTeams()
    }
    
    func didChangeTeams() {
        self.objectWillChange.send()
        debouncer?.send()
    }
    
    static func readFromDisk() -> [String] {
        return storage.array(forKey: "starredTeams") as? [String] ?? []
    }
}
