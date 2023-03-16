//
//  shl_app_ios_widget.swift
//  shl-app-ios-widget
//
//  Created by Pål on 2023-02-11.
//

import WidgetKit
import SwiftUI
import Intents

struct Provider: IntentTimelineProvider {
    let provider = DataProvider()
    
    func placeholder(in context: Context) -> TeamEntry {
        getCachedEntry(teamCode: getStarredTeam() ?? getTopTeam() ?? "FBK")
    }

    func getSnapshot(for configuration: SelectTeamIntent, in context: Context, completion: @escaping (TeamEntry) -> ()) {
        let teamCode = getTeamCode(configuration)
        var entry = getCachedEntry(teamCode: teamCode)
        entry.fetched = .snapshot
        print("getSnapshot \(String(describing: entry))")
        completion(entry)
    }

    func getTimeline(for configuration: SelectTeamIntent, in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        let teamCode = getTeamCode(configuration)

        Task {
            async let async_games = provider.getGames(season: Settings.currentSeason, maxAge: 60)
            async let async_standings = provider.getStandings(season: Settings.currentSeason, maxAge: 60)
            let (games, standings) = await (async_games, async_standings)
            
            print("[WIDGET] fetched games \(String(describing: games))")
            var entry = getEntry(teamCode, games.entries, standings.entries)
            entry.fetched = games.type == .api ? .timeline_api : .timeline_cache
            
            
            // Create the timeline with the entry and a reload policy with the date
            // for the next update.
            let refreshTimeInterval: TimeInterval = 60 * 60 * 2
            let nextUpdateDate = entry.date.addingTimeInterval(refreshTimeInterval)
            let timeline = Timeline(entries: [entry], policy: .after(nextUpdateDate))
            // Call the completion to pass the timeline to WidgetKit.
            completion(timeline)
        }
    }
    
    func getCachedEntry(teamCode: String) -> TeamEntry {
        return getEntry(
            teamCode,
            provider.getCachedGames(season: Settings.currentSeason),
            provider.getCachedStandings(season: Settings.currentSeason))
    }
    
    func getEntry(_ teamCode: String, _ games: [Game]?, _ standings: [Standing]?) -> TeamEntry {
        let standing = StandingsData(data: standings ?? []).getFor(team: teamCode)
        let nextGame = getNextGame(for: teamCode, games: games)
        let points = GamesData(data: games ?? [])
            .getPoints(for: teamCode, numberOfGames: 10)
        return TeamEntry(date: Date(), teamCode: teamCode, standing: standing, game: nextGame, points: points,
                         fetched: .timeline_cache)
    }

    func getNextGame(for teamCode: String, games: [Game]?) -> Game? {
        let live = games?
            .filter({ a in a.hasTeam(teamCode)})
            .filter { $0.isLive() }.first
        return live ?? games?
            .filter({ a in a.hasTeam(teamCode)})
            .filter({ a in a.isFuture() })
            .sorted(by: { (a, b) in a.start_date_time < b.start_date_time })
            .first
    }
    
    func getTeamCode(_ team: SelectTeamIntent) -> String {
        switch (team.team) {
        case .lHF: return "LHF"
        case .fBK: return "FBK"
        case .fHC: return "FHC"
        case .lIF: return "LIF"
        case .bIF: return "BIF"
        case .hV71: return "HV71"
        case .iKO: return "IKO"
        case .mIF: return "MIF"
        case .rBK: return "RBK"
        case .vLH: return "VLH"
        case .tIK: return "TIK"
        case .sAIK: return "SAIK"
        case .lHC: return "LHC"
        case .oHK: return "OHK"
        case .unknown: return getStarredTeam() ?? getTopTeam() ?? "FBK"
        }
    }
    
    func getStarredTeam() -> String? {
        (UserDefaults.shared.array(forKey: "starredTeams") as? [String])?.first
    }
    
    func getTopTeam() -> String? {
        provider.getCachedStandings(season: Settings.currentSeason)?.first?.team_code
    }

}


enum FetchType {
    case timeline_api
    case timeline_cache
    case snapshot
}

struct TeamEntry: TimelineEntry {
    var date: Date
    var teamCode: String
    var standing: Standing?
    var game: Game?
    var points: [Int]?
    var fetched: FetchType
    
    func getOpponent(game: Game) -> String {
        if game.home_team_code == self.teamCode {
            return game.away_team_code
        }
        return game.home_team_code
    }
    
    func getTimeText(game: Game) -> String {
        game.isLive() ? "LIVE" : game.start_date_time.getFormattedDate().uppercased()
    }
    
    func getVsText(game: Game) -> String {
        self.teamCode == game.home_team_code ? "vs" : "@"
    }
    
    func getType() -> String {
        switch self.fetched {
        case .timeline_api: return "☁"
        case .timeline_cache: return "🍪"
        case .snapshot: return "🔫"
        }
    }
}

/**
 * Team Widget
 */
struct TeamWidget: Widget {
    static let provider = Provider()
    let kind: String = "shl_app_ios_widget"

    var body: some WidgetConfiguration {
        IntentConfiguration(kind: kind, intent: SelectTeamIntent.self, provider: TeamWidget.provider) { entry in
            TeamWidgetView(entry: entry)
        }
        .configurationDisplayName("Pucken Lag Widget")
        .description("Följ ditt lag")
        .supportedFamilies(getFamilies())
    }
    
    func getFamilies() -> [WidgetFamily] {
        if #available(iOSApplicationExtension 16.0, *) {
            return  [.systemSmall, .accessoryCircular, .accessoryRectangular]
        } else {
            return  [.systemSmall]
        }
    }
}

struct TeamWidgetView: View {
    @Environment(\.widgetFamily) var family: WidgetFamily
    var entry: Provider.Entry
    
    @ViewBuilder
    var body: some View {
        switch family {
        case .systemSmall: TeamWidgetSystemSmall(entry: entry)
        case .accessoryRectangular: TeamWidgetViewAccessoryRectangular(entry: entry)
        case .accessoryCircular: TeamWidgetViewAccessoryCircular(entry: entry)
        case .accessoryInline: TeamWidgetViewAccessoryInline(entry: entry)
        default: TeamWidgetSystemSmall(entry: entry)
        }
    }
}

struct TeamWidgetSystemSmall: View {
    var entry: Provider.Entry
    
    var body: some View {
        ZStack(alignment: .center) {
            Color(.black)
            VStack(alignment: .leading, spacing: 6) {

                HStack {
                    WidgetTeamLogo(code: entry.teamCode, size: 30)
                    Text(entry.teamCode)
                        .font(.system(size: 26, weight: .heavy, design: .rounded))
                }
                if let s = entry.standing {
                    HStack {
                        Text("#").font(.system(size: 14, weight: .regular, design: .rounded)) +
                        Text("\(s.rank)")
                        Text("\(s.points)") + Text("p").fontWeight(.regular)
                        Text("\(s.gp)") + Text("gp").fontWeight(.regular)
                    }
                }
                if let p = entry.points {
                    Graph(points: p, monochromeColor: .gray)
                        .padding(.top, 4)
                }
                
                if let g = entry.game {
                    HStack(spacing: 4) {
                        Text("\(entry.getTimeText(game:g)) \(entry.getVsText(game: g))")
                            .scaledToFit()
                            .minimumScaleFactor(0.6)
                        WidgetTeamLogo(code: entry.getOpponent(game: g), size: 20)
                    }
                    .padding(.top, 6)
                }
                /*
                HStack(spacing: 0) {
                    Text(entry.date, style: .offset)
                        .frame(width: 80)
                        .minimumScaleFactor(0.2)
                    Text(getType())
                }
                */
            }
            .padding(.top, 0)
            .padding(.leading, 0)
        }
        .foregroundColor(.white)
        .font(.system(size: 16, weight: .bold, design: .rounded).lowercaseSmallCaps())
        
    }
}

struct TeamWidgetViewAccessoryRectangular: View {
    var entry: Provider.Entry
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 6) {
                WidgetTeamLogo(code: entry.teamCode, size: 16)
                Text("\(entry.teamCode)")
                    .font(.system(size: 14, weight: .semibold, design: .rounded).lowercaseSmallCaps())
                    
                if let s = entry.standing {
                    (Text("#").font(.system(size: 11, weight: .semibold, design: .rounded)) +
                    Text("\(s.rank)"))
                        .padding(.leading, -2)
                }
            }
            .font(.system(size: 13, weight: .bold, design: .rounded).lowercaseSmallCaps())
            if let p = entry.points {
                Graph(points: p, height: 15, width: 5, monochromeColor: .white)
            }
            
            
            if let g = entry.game {
                Text("\(entry.getTimeText(game:g)) \(entry.getVsText(game: g)) \(entry.getOpponent(game: g))")
                    .scaledToFit()
                    .minimumScaleFactor(0.6)
            }
        }
        .foregroundColor(.white)
        .font(.system(size: 13, weight: .semibold, design: .rounded).lowercaseSmallCaps())

    }
}

struct TeamWidgetViewAccessoryCircular: View {
    var entry: Provider.Entry
    
    var body: some View {
        WidgetTeamLogo(code: entry.teamCode, size: 46)
    }
}

struct TeamWidgetViewAccessoryInline: View {
    var entry: Provider.Entry
    
    var body: some View {
        if let g = entry.game {
            Text("\(entry.getTimeText(game: g).lowercased()): ") +
            Text("\(g.home_team_code) vs \(g.away_team_code)")
        }
    }
}
/**
 * Standing Widget
 *
struct StandingWidget: Widget {
    let kind: String = "shl_app_ios_standing_widget"

    var body: some WidgetConfiguration {
        IntentConfiguration(kind: kind, intent: SelectTeamIntent.self, provider: Provider()) { entry in
            StandingWidgetView(entry: entry)
        }
        .configurationDisplayName("Standing Widget")
        .description("Följ ditt favorit lag i ligan")
        .supportedFamilies([.systemSmall])
    }
}
struct StandingWidgetView: View {
    var entry: Provider.Entry
    var body: some View {
        ZStack {
            Color(.black)
            VStack {
                HStack {
                    Text("#6")
                    WidgetTeamLogo(code: "TIK", size: 30)
                    Text("33p")
                }.opacity(0.5)
                HStack {
                    Text("#7")
                    WidgetTeamLogo(code: "LHF", size: 30)
                    Text("32p")
                }
                HStack {
                    Text("#8")
                    WidgetTeamLogo(code: "FHC", size: 30)
                    Text("28p")
                }.opacity(0.5)
            }
        }
        .foregroundColor(.white)
        .font(.system(size: 18, weight: .bold, design: .rounded).lowercaseSmallCaps())
    }
}
 **/



struct ShlWidget_Previews: PreviewProvider {
    static var previews: some View {
        let entry = TeamEntry(date: Date(),
                              teamCode: "LHF",
                              standing: Standing(team_code: "LHF", gp: 18, rank: 11, points: 65, diff: 20),
                              game: Game(game_id: 1, game_uuid: "1", away_team_code: "LHF", away_team_result: 0, home_team_code: "SAIK", home_team_result: 0, start_date_time: Date(), game_type: "Regular", played: false, overtime: false, penalty_shots: false, status: "Coming", gametime: nil),
                              points: [3, 2, 2, 0, 0, 3, 3, 1, 2, 3],
                              fetched: .timeline_api
        )
        
        TeamWidgetView(entry: entry)
            .previewContext(WidgetPreviewContext(family: .systemSmall))
            .previewDisplayName("Team Widget")
        
        if #available(iOSApplicationExtension 16.0, *) {
            TeamWidgetView(entry: entry)
                .previewContext(WidgetPreviewContext(family: .accessoryCircular))
                .previewDisplayName("Team Widget - Lock Small")
            TeamWidgetView(entry: entry)
                .previewContext(WidgetPreviewContext(family: .accessoryRectangular))
                .previewDisplayName("Team Widget - Lock Big")
        }
        /*
        StandingWidgetView(entry: entry)
            .previewContext(WidgetPreviewContext(family: .systemSmall))
            .previewDisplayName("Standing Widget")
         */
    }
}
