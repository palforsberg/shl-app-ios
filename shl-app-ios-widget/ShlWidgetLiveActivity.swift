//
//  shl_app_ios_widgetLiveActivity.swift
//  shl-app-ios-widget
//
//  Created by Pål on 2023-02-11.
//

import ActivityKit
import WidgetKit
import SwiftUI

struct WidgetTeamLogo: View {
    var code: String
    var size: CGFloat = 50.0

    var body: some View {
        if let teamImage = UIImage(named: self.getImageName()) {
            Image(uiImage: teamImage)
                .resizable()
                .scaledToFit()
                .frame(width: size, height: size, alignment: .center)
            
        } else {
            Image(systemName: "photo")
                .foregroundColor(Color(uiColor: .secondaryLabel))
        }
    }
    
    func getImageName() -> String {
        if size > 128 {
            return "\(code.lowercased())-big.png"
        }
        return "\(code.lowercased()).png"
    }

}

struct WidgetTeamAvatar: View {
    var code: String
    var body: some View {
        VStack(spacing: 5) {
            WidgetTeamLogo(code: code)
            Text(code)
        }
    }
}


@available(iOS 16.1, *)
@available(iOSApplicationExtension 16.1, *)
struct FullGameInfo: View {
    var context: ActivityViewContext<ShlWidgetAttributes>
    
    var body: some View {
        HStack(alignment: .top, spacing: 40) {
            Spacer()
            WidgetTeamAvatar(code: context.attributes.homeTeam)
            VStack(spacing: 3) {
                HStack(spacing: 10) {
                    Text("\(context.state.homeScore)")
                    Text("-").font(.system(size: 22, weight: .black, design: .rounded))
                    Text("\(context.state.awayScore)")
                }
                .font(.system(size: 40, weight: .heavy, design: .rounded))
                
                HStack(spacing: 3) {
                    if !self.isStale() {
                        if let s = context.state.status {
                            Text(LocalizedStringKey(s))
                        }
                        if let s = context.state.gametime, context.state.getStatus()?.isGameTimeApplicable() ?? false {
                            Text("•")
                            Text(s)
                        }
                    }
                }
                .font(.system(size: 16, weight: .bold, design: .rounded))
            }
            WidgetTeamAvatar(code: context.attributes.awayTeam)
            Spacer()
        }
        .font(.system(size: 14, weight: .heavy, design: .rounded))
    }
    
    func isStale() ->  Bool {
        if #available(iOS 16.2, *) {
            return context.isStale
        }
        return false
    }
}

@available(iOS 16.1, *)
struct ShlWidgetLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: ShlWidgetAttributes.self) { context in
            // Lock screen/banner UI goes here
            FullGameInfo(context: context)
                .padding(EdgeInsets(top: 20, leading: 0, bottom: 20, trailing: 0))
        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded UI goes here.  Compose the expanded UI through
                // various regions, like leading/trailing/center/bottom
                /*DynamicIslandExpandedRegion(.leading) {
                }
                DynamicIslandExpandedRegion(.trailing) {
                }*/
                DynamicIslandExpandedRegion(.bottom) {
                    FullGameInfo(context: context)
                }
            } compactLeading: {
                HStack {
                    WidgetTeamLogo(code: context.attributes.homeTeam, size: 28)
                    Text("\(context.state.homeScore)")
                        .font(.system(size: 20, weight: .heavy, design: .rounded))
                }
            } compactTrailing: {
                HStack {
                    Text("\(context.state.awayScore)")
                        .font(.system(size: 20, weight: .heavy, design: .rounded))
                    WidgetTeamLogo(code: context.attributes.awayTeam, size: 28)
                }
            } minimal: {
                WidgetTeamLogo(code: context.attributes.homeTeam, size: 28)
            }
            .widgetURL(URL(string: "http://www.apple.com"))
            .keylineTint(.yellow)
        }
    }
}

@available(iOS 16.2, *)
struct ShlWidgetLiveActivity_Previews: PreviewProvider {
    static let attributes = ShlWidgetAttributes(homeTeam: "LHF", awayTeam: "FHC", gameUuid: "game_uuid_123")
    static let contentState = ShlWidgetAttributes.ContentState(homeScore: 2, awayScore: 0, gametime: "12:23", status: "Coming")

    static var previews: some View {
        attributes
            .previewContext(contentState, viewKind: .dynamicIsland(.compact))
            .previewDisplayName("Island Compact")
            .environment(\.locale, .init(identifier: "sv"))
        attributes
            .previewContext(contentState, viewKind: .dynamicIsland(.expanded))
            .previewDisplayName("Island Expanded")
            .environment(\.locale, .init(identifier: "sv"))
        attributes
            .previewContext(contentState, viewKind: .dynamicIsland(.minimal))
            .previewDisplayName("Minimal")
            .environment(\.locale, .init(identifier: "sv"))
        attributes
            .previewContext(contentState, viewKind: .content)
            .previewDisplayName("Notification")
            .environment(\.locale, .init(identifier: "sv"))
    }
}
