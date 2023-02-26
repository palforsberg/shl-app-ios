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
            UserDefaults.standard.setValue(starredTeams, forKey: "starredTeams")
            UserDefaults.shared.setValue(starredTeams, forKey: "starredTeams")
            debugPrint("[STARREDTEAMS] write to disk")
        }
    }
    
    init() {
        self.starredTeams = StarredTeams.readFromDisk()
        debugPrint("[STARREDTEAMS] write to shared")
        UserDefaults.shared.setValue(self.starredTeams, forKey: "starredTeams")
    }

    func isStarred(teamCode: String) -> Bool {
        return starredTeams.contains(teamCode)
    }
    
    func isStarred(teamCodes: [String]) -> Bool {
        debugPrint("test \(teamCodes) \(teamCodes.first { isStarred(teamCode: $0) } != nil)")
        return teamCodes.first { isStarred(teamCode: $0) } != nil
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
        return UserDefaults.standard.array(forKey: "starredTeams") as? [String] ?? []
    }
}
