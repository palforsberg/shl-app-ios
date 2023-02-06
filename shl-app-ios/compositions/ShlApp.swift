//
//  HockeyPalApp.swift
//  HockeyPal
//
//  Created by Pål Forsberg on 2021-01-08.
//

import SwiftUI

@main
struct ShlApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    init() {
        UINavigationBar.appearance().largeTitleTextAttributes = [.font: UIFont.rounded(ofSize: 35, weight: .heavy)]
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}



class AppDelegate: NSObject, UIApplicationDelegate {
    
    static var settings = Settings()
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        application.applicationIconBadgeNumber = 0
        return true
    }
    
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        print("[APP] Did receive nofitication \(userInfo)")
        
        let aps = userInfo["aps"] as? [String: Any]
        let alert = aps?["alert"] as? [String: String]
        let title = alert?["title"]
        let body = alert?["body"]
        
        let notif = GameNofitication (team: userInfo["team"] as? String, game_uuid: userInfo["game_uuid"] as? String, title: title, body: body, type: userInfo["type"] as? String)
        NotificationCenter.default.post(name: .onGameNotification, object: notif)
        completionHandler(UIBackgroundFetchResult.noData)
    }
    
    /**
     1: registerForPushNotifications and request user permission
     2: getNotificationSettings and register for remote notifications
     3: didRegisterForRemoteNotificationsWithDeviceToken or didFailToRegisterForRemoteNotificationsWithError handle token or error
     */
    static func registerForPushNotifications() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
            print("[APP] Permission granted: \(granted)")
            guard granted else { return }
            AppDelegate.getNotificationSettings()
        }
    }
    
    static func getNotificationSettings() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            guard settings.authorizationStatus == .authorized else { return }
            DispatchQueue.main.async {
                UIApplication.shared.registerForRemoteNotifications()
            }
        }
    }

    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        let tokenParts = deviceToken.map { data in String(format: "%02.2hhx", data) }
        let token = tokenParts.joined()
        print("[APP] Device Token: \(token)")
        AppDelegate.settings.apnToken = token
    }

    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("[APP] Failed to register: \(error.localizedDescription)")
    }
}


extension NSNotification.Name {
    static let onGameNotification = Notification.Name("onGameNotification")
}

struct GameNofitication: Equatable {
    let team: String?
    let game_uuid: String?
    let title: String?
    let body: String?
    let type: String?
}
