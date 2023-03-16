//
//  UserService.swift
//  shl-app-ios
//
//  Created by Pål on 2021-08-09.
//

import Foundation
import Combine

class UserService {
    
    var provider: DataProvider?
    var debouncer: Debouncer
    var cancellables: [AnyCancellable] = []
    
    init(provider: DataProvider?, settings: Settings, starredTeams: StarredTeams) {
        self.provider = provider
        self.debouncer = Debouncer({
            let apnToken = settings.notificationsEnabled ? settings.apnToken : nil
            let request = AddUser(id: settings.uuid, apn_token: apnToken, teams: starredTeams.starredTeams, ios_version: UserService.getOsVersion(), app_version: UserService.getBuildVersionNumber())
            Task {
                await provider?.addUser(request: request)
            }
        }, seconds: 1)
        
        // when any of the parameters change, send to debouncer which updates the server
        cancellables = [
            starredTeams.$starredTeams.sink { _ in self.debouncer.send() },
            settings.$apnToken.sink { _ in self.debouncer.send() },
            settings.$notificationsEnabled.sink { _ in self.debouncer.send() }
        ]
    }
    
    static func getOsVersion() -> String {
        let os = ProcessInfo.processInfo.operatingSystemVersion
        return String(os.majorVersion) + "." + String(os.minorVersion) + "." + String(os.patchVersion)
    }
    
    static func getBuildVersionNumber() -> String? {
        return Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
    }
}
