//
//  shl_app_ios_widgetBundle.swift
//  shl-app-ios-widget
//
//  Created by Pål on 2023-02-11.
//

import WidgetKit
import SwiftUI

@main
struct ShlWidgetBundle: WidgetBundle {
    var body: some Widget {
        TeamWidget()
        /*if #available(iOSApplicationExtension 16.1, *) {
            ShlWidgetLiveActivity()
        }*/
    }
}
