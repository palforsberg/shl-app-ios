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
            async let async_playoffs = provider.getPlayoffs(season: Settings.currentSeason, maxAge: 60)
            async let async_teams = provider.getTeams()
            
            let (games, standings, playoffs, teams) = await (async_games, async_standings, async_playoffs, async_teams)
            
            print("[WIDGET] fetched games for \(teamCode)")
            var entry = getEntry(teamCode, games.entries, standings.entries, playoffs.entries, TeamsData(teams: teams ?? []))
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
            provider.getCachedStandings(season: Settings.currentSeason),
            provider.getCachedPlayoffs(season: Settings.currentSeason),
            TeamsData(teams: provider.getCachedTeams() ?? [])
        )
    }
    
    func getEntry(_ teamCode: String,
                  _ games: [Game]?,
                  _ standings: StandingRsp?,
                  _ playoffs: PlayoffRsp?,
                  _ teams: TeamsData?
    ) -> TeamEntry {
        let gamesData = GamesData(data: games ?? [])
        let playOffData = PlayoffData(data: playoffs)
        let standing = StandingsData(data: standings ?? StandingRsp(SHL: [], HA: [])).getFor(team: teamCode)
        
        var points: [Int] = []
        var playoffStage: String?
        
        if let entry = playOffData.getEntry(team: teamCode) {
            let opponent = entry.team1 == teamCode ? entry.team2 : entry.team1
            playoffStage = playOffData.getStage(entry: entry)
            points = gamesData.getPlayoffPoints(for: teamCode, team2: opponent, numberOfGames: entry.getNrGames())
        } else {
            points = gamesData.getPoints(for: teamCode, numberOfGames: 10)
        }
        let nextGame = getNextGame(for: teamCode, games: games)
        
        return TeamEntry(date: Date(),
                         teamCode: teamCode,
                         standing: standing,
                         game: nextGame,
                         points: points,
                         playoffStage: playoffStage,
                         fetched: .timeline_cache,
                         teams: teams)
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
        case .aIK: return "AIK"
        case .aIS: return "AIS"
        case .dIF: return "DIF"
        case .nYB: return "NYB"
        case .kHC: return "KHC"
        case .bIK: return "BIK"
        case .mODO: return "MODO"
        case .kRI: return "KRI"
        case .vIK: return "VIK"
        case .vVIK: return "VVIK"
        case .tAIF: return "TAIF"
        case .mIK: return "MIK"
        case .iFB: return "IFB"
        case .sSK: return "SSK"
        case .oSIK: return "OSIK"
        case .unknown: return getStarredTeam() ?? getTopTeam() ?? "FBK"
        }
    }
    
    func getStarredTeam() -> String? {
        let starredTeam = (UserDefaults.shared.stringArray(forKey: "starredTeams"))?.first
        print("[WIDGET] Get starred team \(starredTeam ?? "(none)")")
        return starredTeam
    }
    
    func getTopTeam() -> String? {
        provider.getCachedStandings(season: Settings.currentSeason)?.SHL.first?.team_code
    }
}


enum FetchType {
    case timeline_api
    case timeline_cache
    case snapshot
}

extension View {
    func widgetBackground() -> some View {
        if #available(iOSApplicationExtension 17.0, *) {
            return containerBackground(.black, for: .widget)
        }
        return self
    }
}

struct TeamEntry: TimelineEntry {
    var date: Date
    var teamCode: String
    var standing: Standing?
    var game: Game?
    var points: [Int]?
    var playoffStage: String?
    var fetched: FetchType
    var teams: TeamsData?
    
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
    
    func getDisplayCode(_ teamCode: String) -> String {
        self.teams?.getDisplayCode(teamCode) ?? teamCode
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
                    Text(entry.getDisplayCode(entry.teamCode))
                        .font(.system(size: 24, weight: .heavy, design: .rounded))
                }
                if let s = entry.playoffStage {
                    Text(LocalizedStringKey(s)).padding(.top, 3)
                        .font(.system(size: 14, weight: .heavy, design: .rounded))
                        .textCase(.uppercase)
                        .scaledToFit()
                        .minimumScaleFactor(0.7)
                } else if let s = entry.standing {
                    HStack {
                        Text("#").font(.system(size: 14, weight: .semibold, design: .rounded)) +
                        Text("\(s.rank)")
                        Text("\(s.points)") + Text("p").fontWeight(.semibold)
                        Text("\(s.gp)") + Text("gp").fontWeight(.semibold)
                    }
                }
                
                if let p = entry.points {
                    if entry.playoffStage != nil {
                        PlayoffGraph(points: p)
                            .padding(.top, 4)
                    } else if p.count > 0 {
                        Graph(points: p, monochromeColor: .gray)
                            .padding(.top, 4)
                    }
                }
                
                if let g = entry.game {
                    HStack(spacing: 4) {
                        Text("\(entry.getTimeText(game:g)) \(entry.getVsText(game: g))")
                            .scaledToFit()
                            .minimumScaleFactor(0.6)
                        WidgetTeamLogo(code: entry.getOpponent(game: g), size: 20)
                    }
                    .padding(.top, 3)
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
        .font(.system(size: 16, weight: .heavy, design: .rounded).lowercaseSmallCaps())
        .widgetBackground()
        
    }
}

struct TeamWidgetViewAccessoryRectangular: View {
    var entry: Provider.Entry
    
    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            HStack(spacing: 5) {
                WidgetTeamLogo(code: entry.teamCode, size: 16)
                Text("\(entry.getDisplayCode(entry.teamCode))")
                    .font(.system(size: 14, weight: .heavy, design: .rounded).lowercaseSmallCaps())
                    
                if let s = entry.standing {
                    (Text("#").font(.system(size: 11, weight: .semibold, design: .rounded)) +
                    Text("\(s.rank)"))
                        .padding(.leading, -2)
                }
            }
            .font(.system(size: 13, weight: .heavy, design: .rounded).lowercaseSmallCaps())
            
            
            if let s = entry.playoffStage {
                HStack(spacing: 3) {
                    Text(LocalizedStringKey(s)).textCase(.uppercase)
                    Text("•")
                    Text("\(entry.points?.filter { [2, 3].contains($0) }.count ?? 0):\(entry.points?.filter { [0, 1].contains($0) }.count ?? 0) ")
                        .fontWeight(.bold)
                    
                }
            } else if let p = entry.points, p.count > 0 {
                Graph(points: p, monochromeColor: .white)
            }
            
            
            if let g = entry.game {
                Text("\(entry.getTimeText(game:g)) \(entry.getVsText(game: g)) \(entry.getDisplayCode(entry.getOpponent(game: g)))")
                    .scaledToFit()
                    .minimumScaleFactor(0.6)
            }
        }
        .foregroundColor(.white)
        .font(.system(size: 12, weight: .bold, design: .rounded).lowercaseSmallCaps())
        .widgetBackground()

    }
}

struct TeamWidgetViewAccessoryCircular: View {
    var entry: Provider.Entry
    
    var body: some View {
        WidgetTeamLogo(code: entry.teamCode, size: 46)
            .widgetBackground()
    }
}

struct TeamWidgetViewAccessoryInline: View {
    var entry: Provider.Entry
    
    var body: some View {
        if let g = entry.game {
            Text("\(entry.getTimeText(game: g).capitalized) - ") +
            Text("\(g.home_team_code) vs \(g.away_team_code)")
        }
    }
}

struct ShlWidget_Previews: PreviewProvider {
    static var previews: some View {
        let entry = TeamEntry(date: Date(),
                              teamCode: "LHF",
                              standing: Standing(team_code: "LHF", gp: 18, rank: 11, points: 65, diff: 20, league: .shl),
                              game: Game(game_uuid: "1", away_team_code: "LHF", away_team_result: 0, home_team_code: "SAIK", home_team_result: 0, start_date_time: Date(), game_type: "Regular", played: false, overtime: false, shootout: false, status: "Coming", gametime: nil, league: .shl, votes: nil),
                              points: [3, 2, 2, 0, 0, 3, 3, 1, 2, 3],
                              fetched: .timeline_api,
                              teams: getTeamsData()
        )
        let playoffTeamEntry = TeamEntry(date: Date(),
                              teamCode: "LHF",
                              standing: Standing(team_code: "LHF", gp: 18, rank: 11, points: 65, diff: 20, league: .shl),
                                         game: Game(game_uuid: "1", away_team_code: "LHF", away_team_result: 0, home_team_code: "SAIK", home_team_result: 0, start_date_time: Date(), game_type: "Regular", played: false, overtime: false, shootout: false, status: "Coming", gametime: nil, league: .shl, votes: nil),
                                         points: [3, 3, 0, 3, -1, -1, -1],
                                         playoffStage: "Quarterfinal",
                              fetched: .timeline_api,
                                         teams: getTeamsData()
        )
        
        TeamWidgetView(entry: entry)
            .previewContext(WidgetPreviewContext(family: .systemSmall))
            .previewDisplayName("Team Widget")
        
        TeamWidgetView(entry: playoffTeamEntry)
            .previewContext(WidgetPreviewContext(family: .systemSmall))
            .previewDisplayName("Team Widget - Playoff")
            .environment(\.locale, .init(identifier: "sv"))
        
        if #available(iOSApplicationExtension 16.0, *) {
            TeamWidgetView(entry: entry)
                .previewContext(WidgetPreviewContext(family: .accessoryCircular))
                .previewDisplayName("Team Widget - Lock Small")
            
                TeamWidgetView(entry: entry)
                    .previewContext(WidgetPreviewContext(family: .accessoryInline))
                    .previewDisplayName("Team Widget - Lock Inline")
            TeamWidgetView(entry: entry)
                .previewContext(WidgetPreviewContext(family: .accessoryRectangular))
                .previewDisplayName("Team Widget - Lock Big")
            
            TeamWidgetView(entry: playoffTeamEntry)
                .previewContext(WidgetPreviewContext(family: .accessoryRectangular))
                .previewDisplayName("Team Widget - Lock Big - Playoff")
                .environment(\.locale, .init(identifier: "sv"))
        }
        /*
        StandingWidgetView(entry: entry)
            .previewContext(WidgetPreviewContext(family: .systemSmall))
            .previewDisplayName("Standing Widget")
         */
    }
}
