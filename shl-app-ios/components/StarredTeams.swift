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
            StarredTeams.storage.setValue(starredTeams, forKey: "starredTeams")
            StarredTeams.storage.synchronize()
        }
    }
    
    private static var storage = UserDefaults.standard
    
    init() {
        self.starredTeams = StarredTeams.readFromDisk()
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
    }
    
    static func readFromDisk() -> [String] {
        return storage.array(forKey: "starredTeams") as? [String] ?? []
    }
}
