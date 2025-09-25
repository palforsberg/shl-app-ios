//
//  LiveActivity.swift
//  shl-app-ios
//
//  Created by Pål on 2023-03-05.
//

import Foundation
import ActivityKit

class LiveActivity {
    
    public static var shared: LiveActivity?
    
    var provider: DataProvider?
    var settings: Settings
    
    var listener: (game_uuid: String, call: (Bool) -> ())?
    
    init(provider: DataProvider?, settings: Settings) {
        self.provider = provider
        self.settings = settings
        
        self.listenToAllPastAcitivities()
    }
    
    func setListener(game_uuid: String, listener: @escaping (Bool) -> ()) {
        self.listener = (game_uuid: game_uuid, call: listener)
    }
    
    func isEnabled(gameUuid: String) -> Bool {
        let activity = Activity<ShlWidgetAttributes>.activities
            .first(where: { a in a.attributes.gameUuid == gameUuid })
        return activity != nil
    }
    
    func isGameApplicable(game: Game) -> Bool {
        if game.isLive() {
            return true
        }
        if game.isFuture() {
            let diffComponents = Calendar.current.dateComponents([.hour], from: Date(), to: game.start_date_time)
            return abs(diffComponents.hour ?? 0) < 4
        }
        return false
    }
    
    func startLiveActivity(for game: Game, teamsData: TeamsData) async {
        do {
            await self.endLiveActivity(for: game)
            
            let result = try Activity.request(attributes: ShlWidgetAttributes.from(game, teamsData: teamsData), contentState: ShlWidgetAttributes.ContentState.from(game), pushType: .token)
            print("[LIVE] Start \(game.home_team_code) - \(game.away_team_code)")

            self.listenToPushTokenUpdates(result)
            self.listenToStateUpdates(result)
        } catch (let error) {
            print("[LIVE] Error starting \(error.localizedDescription).")
        }
    }
    
    func endLiveActivity(for game: Game) async {
        guard let a = Activity<ShlWidgetAttributes>.activities.first(where: {a in a.attributes.gameUuid == game.game_uuid }) else {
            return
        }
        await a.end(using: a.contentState, dismissalPolicy: .immediate)
        print("[LIVE] Manually End Live Activity \(a.attributes.homeTeam) \(a.attributes.awayTeam)")
    }
    

    private func listenToAllPastAcitivities() {
        Activity<ShlWidgetAttributes>.activities.forEach { a in
            print("[LIVE] Listen to \(a.attributes.homeTeam) - \(a.attributes.awayTeam)")
            self.listenToPushTokenUpdates(a)
            self.listenToStateUpdates(a)
        }
    }
    
    private func listenToPushTokenUpdates(_ activity: Activity<ShlWidgetAttributes>) {
        Task {
            for await data in activity.pushTokenUpdates {
                let new_token = data.token()
                print("[LIVE] Updated Token \(activity.attributes.homeTeam) \(activity.attributes.awayTeam) \(new_token)")
                await provider?.startLiveActivity(StartLiveActivity(user_id: settings.uuid, token: new_token, game_uuid: activity.attributes.gameUuid))
            }
        }
    }
    
    private func listenToStateUpdates(_ activity: Activity<ShlWidgetAttributes>) {
        Task {
            for await a in activity.activityStateUpdates {
                if a == .active || isStale(a) {
                    print("[LIVE] Started \(activity.attributes.homeTeam) \(activity.attributes.awayTeam)")
                    if activity.attributes.gameUuid == self.listener?.game_uuid {
                        self.listener?.call(true)
                    }
                }
                if  a == .ended || a == .dismissed {
                    print("[LIVE] Ended \(activity.attributes.homeTeam) \(activity.attributes.awayTeam)")
                    if activity.attributes.gameUuid == self.listener?.game_uuid {
                        self.listener?.call(false)
                    }
                    await provider?.endLiveActivity(EndLiveActivity(user_id: settings.uuid, game_uuid: activity.attributes.gameUuid))
                }
                
            }
        }
    }
    
    private func isStale(_ state: ActivityState) -> Bool {
        if state == .stale {
            return true
        }
        return false
        
    }
}
