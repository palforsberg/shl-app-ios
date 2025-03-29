//
//  GameEventView.swift
//  shl-app-ios
//
//  Created by Pål on 2025-03-26.
//

import SwiftUI
import TipKit


struct TapEventTip: Tip {
    var id = "tap-event-tip-6"
    
    var title: Text {
        Text("tap-event-tip-title")
    }
    var message: Text? {
        Text("tap-event-tip-message")
    }
}

struct PenaltyEventRow: View {
    var event: GameEvent
    var selectEvent: (GameEvent) -> Void
    
    @EnvironmentObject var teamsData: TeamsData
    var body: some View {
        Button(action: { self.selectEvent(event) }, label: {
            HStack(spacing: 10) {
                TeamLogo(code: event.team ?? "", size: 28)
                VStack (spacing: 2) {
                    HStack(spacing: 2) {
                        Text(LocalizedStringKey("Penalty"))
                        Image("whistle_small", bundle: Bundle.main)
                            .resizable()
                            .frame(width: 16, height: 16, alignment: .center)
                            .scaledToFit()
                            .offset(y: 1)
                            .opacity(0.8)
                        Spacer()
                        Text(event.penalty ?? "")
                    }.font(.system(size: 16, weight: .semibold, design: .rounded))
                        .cornerRadius(10)
                    HStack {
                        if let player = event.player {
                            Text("#\(player.jersey) \(player.first_name) \(player.family_name)").truncationMode(.tail).lineLimit(1)
                        }
                        Text(event.reason ?? "").truncationMode(.tail).lineLimit(1)
                        Spacer()
                        Text(event.gametime)
                    }.font(.system(size: 14, weight: .medium, design: .rounded))
                }
                
            }
            .padding(EdgeInsets(top: 7, leading: 30, bottom: 8, trailing: 35))
            .foregroundColor(Color(uiColor: .secondaryLabel))
            .contentShape(Rectangle())
        })
        .buttonStyle(ActiveButtonStyle())
    }
}

struct PenaltyEventExpandedView: View {
    var event: GameEvent
    var details: GameDetails?
    
    @EnvironmentObject var teamsData: TeamsData
    
    var body: some View {
        ScrollView {
            Spacer(minLength: 20)
            HStack(spacing: 4) {
                Text(LocalizedStringKey("Penalty"))
                    .font(.system(size: 26, weight: .heavy, design: .rounded).smallCaps())
                Image("whistle_small", bundle: Bundle.main)
                    .resizable()
                    .frame(width: 24, height: 24, alignment: .center)
                    .scaledToFit()
                    .offset(y: 2)
            }
                
            Spacer(minLength: 16)
            
            HStack(spacing: 6) {
                Text(event.reason ?? "")
                Text("•")
                Text(event.penalty ?? "")
            }
            .font(.system(size: 20, weight: .bold, design: .rounded))
            
            Spacer(minLength: 6)
            
            HStack(spacing: 4) {
                Text(LocalizedStringKey(event.status))
                Text("•")
                Text(event.gametime)
            }
            .font(.system(size: 16, weight: .bold, design: .rounded))
            
            Group {
                if let player = event.player {
                    Spacer(minLength: 10)
                    GePlayerView(player: player, imageSize: 90, gameDetails: details)
                }
            }
            .padding(EdgeInsets(top: 0, leading: 40, bottom: 0, trailing: 40))
            Spacer()
        }
        .font(.system(size: 16, weight: .semibold, design: .rounded))
        .padding(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
    }
}

struct GoalEventRow: View {
    var event: GameEvent
    var game: Game
    var selectEvent: (GameEvent) -> Void
    
    @EnvironmentObject var teamsData: TeamsData
    @EnvironmentObject var starredTeams: StarredTeams
    
    var body: some View {
        let team = event.team ?? ""
        let starred = starredTeams.isStarred(teamCode: team)

        Button(action: { self.selectEvent(event) }, label: {
            HStack(spacing: 10) {
                TeamLogo(code: team, size: 28)
                VStack (spacing: 2) {
                    HStack {
                        if starred {
                            Text(LocalizedStringKey("Goal_starred"))
                        } else {
                            Text(LocalizedStringKey("Goal"))
                        }
                        Spacer()
                        Text("\(event.home_team_result ?? 0)").underline(team == game.home_team_code) +
                        Text(" - ") +
                        Text("\(event.away_team_result ?? 0)").underline(team == game.away_team_code)
                    }.font(.system(size: starred ? 20 : 20, weight: .heavy, design: .rounded))
                    HStack {
                        if let player = event.player {
                            Text("#\(player.jersey) \(player.first_name) \(player.family_name)")
                        }
                        Text(event.getTeamAdvantage())
                        Spacer()
                        Text(event.gametime)
                    }.font(.system(size: starred ? 14 : 14, weight: .semibold, design: .rounded))
                }
            }
            .contentShape(Rectangle())
            .padding(EdgeInsets(top: 10, leading: 30, bottom: 10, trailing: 35))
        })
        
        .buttonStyle(ActiveButtonStyle())
    }
}

struct GoalEventExpandedView: View {
    var event: GameEvent
    var game: Game
    var details: GameDetails?
    
    @EnvironmentObject var teamsData: TeamsData
    @EnvironmentObject var starredTeams: StarredTeams
    
    var body: some View {
        let team = event.team ?? ""
        let starred = starredTeams.isStarred(teamCode: team)

        ScrollView {
            Spacer(minLength: 20)
            Text(LocalizedStringKey(starred ? "Goal_starred" : "Goal"))
                .font(.system(size: 26, weight: .heavy, design: .rounded).smallCaps())
            
            Spacer(minLength: 20)
            HStack(alignment: .center, spacing: 2) {
                Spacer()
                TeamAvatar(game.home_team_code, alignment: .leading)
                
                Text("\(event.home_team_result ?? 0)")
                    .flashing(enabled: team == game.home_team_code)
                Text(" - ")
                Text("\(event.away_team_result ?? 0)")
                    .flashing(enabled: team == game.away_team_code)
        
                TeamAvatar(game.away_team_code, alignment: .trailing)
                Spacer()
            }
            .font(.system(size: 30, weight: .heavy, design: .rounded))
            
            Spacer(minLength: 6)
            
            HStack(spacing: 3) {
                Text(LocalizedStringKey(event.status))
                Text("•")
                Text(event.gametime)
                let adv = event.getTeamAdvantage()
                if !adv.isEmpty {
                    Text(" \(adv)")
                }
            }.font(.system(size: 16, weight: .bold, design: .rounded))
        
            
            Group {
                if let player = event.player {
                    Spacer(minLength: 16)
                    GePlayerView(player: player, imageSize: 90, gameDetails: details)
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                }
                
                if let assists = event.getAssists() {
                    Spacer(minLength: 30)
                    GeSectionTitle(text: "Assist")
                    VStack {
                        ForEach(assists) { player in
                            GePlayerView(player: player, imageSize: 60, gameDetails: details)
                        }
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                    }
                }
            }
            .padding(EdgeInsets(top: 0, leading: 40, bottom: 0, trailing: 40))
            Spacer()
        }
        .font(.system(size: 16, weight: .semibold, design: .rounded))
        .padding(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
    }
}


extension View {
    func flashing(enabled: Bool) -> some View {
        return modifier(FlashingModifier(enabled: enabled))
    }
}

private struct FlashingModifier: ViewModifier {
    let enabled: Bool
    @State private var isVisible = true

    func body(content: Content) -> some View {
        content
            .opacity(isVisible ? 1 : 0.05)
            .onAppear {
                if enabled {
                    withAnimation(
                        .easeInOut(duration: 0.6)
                        .delay(0.2)
                        .repeatForever(autoreverses: true)
                    ) {
                        isVisible = false
                    }
                }
            }
    }
}

struct GePlayerView: View {
    var player: EventPlayer
    var imageSize: CGFloat = 50
    
    var gameDetails: GameDetails?
    
    @EnvironmentObject var teams: TeamsData
    
    var body: some View {
        let basePlayer = gameDetails?.findPlayer(player.id)
        HStack(spacing: 16) {
            PlayerImage(player: "\(player.id ?? "")", size: imageSize)
            VStack(spacing: 3) {
                HStack {
                    Text("\(player.first_name) \(player.family_name)")
                    Spacer()
                }
                .font(.system(size: 18, weight: .bold, design: .rounded))
                
                if let bp = basePlayer {
                    HStack {
                        TeamLogo(code: bp.team_code, size: 16)
                        Text("\(teams.getDisplayCode(bp.team_code))")
                        Text("#\(player.jersey)")
                        Text(bp.position)
                        Spacer()
                    }
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundColor(Color(uiColor: .secondaryLabel))
                }
            }
        }
    }
}

struct GeSectionTitle: View {
    var text: String
    
    var body: some View {
        HStack {
            Text(text)
            Spacer()
        }
        .font(.system(size: 14, weight: .bold, design: .rounded))
        .foregroundColor(Color(uiColor: .secondaryLabel))
        .textCase(.uppercase)
    }
}


struct GameStartEventRow: View {
    var event: GameEvent
    var body: some View {
        HStack {
            Text(LocalizedStringKey(self.event.type))
            Spacer()
        }
            .foregroundColor(Color(uiColor: UIColor.secondaryLabel))
            .font(.system(size: 14, weight: .semibold, design: .rounded))
            .padding(EdgeInsets(top: 2, leading: 67, bottom: 2, trailing: 0))
    }
}

struct PeriodEventRow: View {
    var event: GameEvent
    var body: some View {
        HStack {
            Text(self.getLocalizedString())
            Spacer()
        }
            .foregroundColor(Color(uiColor: UIColor.secondaryLabel))
            .font(.system(size: 14, weight: .semibold, design: .rounded))
            .padding(EdgeInsets(top: 2, leading: 67, bottom: 2, trailing: 0))
    }
    
    private func getLocalizedString() -> LocalizedStringKey {
        
        switch self.event.getEventType() {
        case .periodStart:
            if event.status == "Shootout" {
                return LocalizedStringKey("PenaltiesStart")
            } else if event.status == "Overtime" {
                return LocalizedStringKey("OvertimeStart")
            }
            return LocalizedStringKey("PeriodStart \(getPeriod(s: event.status))")
        case .periodEnd:
            if event.status == "Shootout" {
                return LocalizedStringKey("PenaltiesEnd")
            } else if event.status == "Overtime" {
                return LocalizedStringKey("OvertimeEnd")
            }
            return LocalizedStringKey("PeriodEnd \(getPeriod(s: event.status))")
        default: return LocalizedStringKey("")
        }
    }
    
    private func getPeriod(s: String) -> String {
        switch s {
        case "Period1": return "1"
        case "Period2": return "2"
        case "Period3": return "3"
        default: return "1"
        }
    }
}

struct GameEventRow: View {
    var event: GameEvent
    var game: Game
    var selectEvent: (GameEvent) -> Void
    
    var body: some View {
        switch event.getEventType() {
        case .gameStart, .gameEnd: return AnyView(GameStartEventRow(event: event))
        case .goal: return AnyView(GoalEventRow(event: event, game: game, selectEvent: selectEvent))
        case .periodStart, .periodEnd: return AnyView(PeriodEventRow(event: event))
        case .penalty: return AnyView(PenaltyEventRow(event: event, selectEvent: selectEvent))
        default: return AnyView(Text(""))
        }
    }
}

struct GameEventExpandedView: View {
    var event: GameEvent
    var game: Game
    var details: GameDetails?
    var body: some View {
        switch event.getEventType() {
        case .gameStart, .gameEnd: return AnyView(GameStartEventRow(event: event))
        case .goal: return AnyView(GoalEventExpandedView(event: event, game: game, details: details))
        case .periodStart, .periodEnd: return AnyView(PeriodEventRow(event: event))
        case .penalty: return AnyView(PenaltyEventExpandedView(event: event, details: details))
        default: return AnyView(Text(""))
        }
    }
}

struct GameEventView: View {
    @State var selectedEvent: GameEvent?
    
    var game: Game
    var details: GameDetails?
    
    var tapTip = TapEventTip()
    
    var body: some View {
        let events = details?.events ?? []
        let firstGoalForTip = (events.first { $0.type == "Goal" || $0.type == "Penalty" })?.id
        Group {
            ForEach(events) { p in
                if #available(iOS 17.0, *), p.id == firstGoalForTip {
                    TipView(tapTip, arrowEdge: .bottom)
                }
                GameEventRow(event: p, game: game, selectEvent: selectEvent)
            }
        }
        .sheet(item: $selectedEvent) { event in
            GameEventExpandedView(event: event, game: game, details: details)
                .presentationDetents([.medium, .large])
                .id(event.event_id)
        }
    }
    
    func selectEvent(event: GameEvent) {
        self.selectedEvent = event
    }
}

#Preview {
    GameEventView(game: getPlayedGame(), details: GameDetails(
        game: getPlayedGame(),
        events: [
        getEvent(type: .gameStart),
        getEvent(type: .periodStart, period: 1),
        getEvent(type: .penalty),
        getEvent(type: .periodEnd),
        getEvent(type: .periodStart, period: 2),
        getEvent(type: .goal),
        getEvent(type: .goal, period: 2, team: "FHC"),
        getEvent(type: .penalty),
        getEvent(type: .periodEnd, period: 2),
        getEvent(type: .periodStart, period: 99),
        getEvent(type: .goal),
    ], 
        stats: ApiGameStats(home: ApiGameTeamStats(g: 0, sog: 0, pim: 0, fow: 0), away: ApiGameTeamStats(g: 0, sog: 0, pim: 0, fow: 0)),
        players: [getPlayer(id: 524, g: 1, a: 2, pim: 3)]))
    .environmentObject(GamesData(data: []))
    .environmentObject(Settings())
    .environmentObject(getPickemData())
    .environmentObject(getTeamsData())
    .environmentObject(getStandingsData())
    .environmentObject(StarredTeams())
    .environment(\.locale, .init(identifier: "sv"))
}

#Preview {
    GoalEventExpandedView(
        event: getEvent(type: .goal),
        game: getPlayedGame(),
        details: GameDetails(game: getPlayedGame(), events: [], stats: nil, players: [getPlayer(id: 524, g: 2, a: 1, pim: 20)])
    )
    .environmentObject(GamesData(data: []))
    .environmentObject(Settings())
    .environmentObject(getPickemData())
    .environmentObject(getTeamsData())
    .environmentObject(getStandingsData())
    .environmentObject(StarredTeams())
    .environment(\.locale, .init(identifier: "sv"))
}

#Preview {
    PenaltyEventExpandedView(
        event: getEvent(type: .penalty),
        details: GameDetails(game: getPlayedGame(), events: [], stats: nil, players: [getPlayer(id: 524, g: 2, a: 1, pim: 20)])
    )
    .environmentObject(GamesData(data: []))
    .environmentObject(Settings())
    .environmentObject(getPickemData())
    .environmentObject(getTeamsData())
    .environmentObject(getStandingsData())
    .environmentObject(StarredTeams())
    .environment(\.locale, .init(identifier: "sv"))
}
