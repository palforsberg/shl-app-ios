//
//  HockeyPalApp.swift
//  HockeyPal
//
//  Created by Pål Forsberg on 2021-01-08.
//

import SwiftUI

@main
struct ShlApp: App {
    init() {
        UINavigationBar.appearance().largeTitleTextAttributes = [.font: UIFont.rounded(ofSize: 35, weight: .bold)]
    }
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
