//
//  Data.swift
//  HockeyPal
//
//  Created by Pål Forsberg on 2021-01-08.
//

import Foundation
import WidgetKit

#if DEBUG
let baseUrl = "http://192.168.141.229:8080"
#else
let baseUrl = "https://palsserver.com/shl-api"
#endif
let gamesUrl = { (season: Int) -> String in return "\(baseUrl)/games/\(season)" }
let standingsUrl = { (season: Int) -> String in return "\(baseUrl)/standings/\(season)" }
let teamsUrl = "\(baseUrl)/teams?season=\(Settings.currentSeason)"
let playoffUrl = "\(baseUrl)/playoffs/\(Settings.currentSeason)"
let userUrl = "\(baseUrl)/user"
let gameStatsUrl = { (game: Game) -> String in
    return "\(baseUrl)/game/\(game.game_uuid)/\(game.game_id)"
}
let playersUrl = { (code: String) -> String in
    "\(baseUrl)/players/\(code)"
}

enum GetType {
    case cache
    case api
    case throttled
}

class DataProvider {
    
    private let apiJsonDecoder = getJsonDecoder()

    init() {
    }
    
    func getGames(season: Int, fetchType: GetType = .throttled, maxAge seconds: TimeInterval = 10) async -> (entries: [Game]?, type: GetType) {
        let url = gamesUrl(season)
        let type = [Game].self
        switch fetchType {
        case .throttled: return await getThrottledData(url: url, type: type, maxAge: seconds)
        case .cache: return (Cache.retrieve(key: url, type: type), fetchType)
        case .api: return (await getData(url: url, type: type), fetchType)
        }
    }
    
    func getCachedGames(season: Int) -> [Game]? {
        return Cache.retrieve(key: gamesUrl(season), type: [Game].self)
    }
    
    func getStandings(season: Int, fetchType: GetType = .throttled, maxAge seconds: TimeInterval = 10) async -> (entries: [Standing]?, type: GetType) {
        let url = standingsUrl(season)
        let type = [Standing].self
        switch fetchType {
        case .throttled: return await getThrottledData(url: url, type: type, maxAge: seconds)
        case .cache: return (Cache.retrieve(key: url, type: type), fetchType)
        case .api: return (await getData(url: url, type: type), fetchType)
        }
    }
    
    func getCachedStandings(season: Int) -> [Standing]? {
        return Cache.retrieve(key: standingsUrl(season), type: [Standing].self)
    }
    
    func getGameStats(game: Game) async -> GameStats? {
        return await getData(url: gameStatsUrl(game), type: GameStats.self)
    }
    
    func getTeams() async -> [Team]? {
        if let cached = Cache.retrieve(key: teamsUrl, type: [Team].self) {
            return cached
        }
        return await getData(url: teamsUrl, type: [Team].self)
    }
    
    func getThrottledPlayoffs() async -> (entries: Playoffs?, type: GetType) {
        return await getThrottledData(url: playoffUrl, type: Playoffs.self, maxAge: 10)
    }
    
    func getPlayers(for code: String) async -> [PlayerStats]? {
        return await getThrottledData(url: playersUrl(code), type: [PlayerStats].self, maxAge: 10).entries
    }
    
    func addUser(request: AddUser) async {
        await postData(url: userUrl, data: request)
    }
    
    
    /**
     maxAge; maxage of the stored data  in seconds before fetching new
     */
    func getThrottledData<T: Codable>(url: String, type: T.Type, maxAge seconds: TimeInterval) async -> (entries: T?, type: GetType) {
        let dateKey = "\(url)_latest_date"
        
        let lastFetch = Cache.retrieve(key: dateKey, type: Date.self) ?? Date(timeIntervalSince1970: 0)
        
        if -lastFetch.timeIntervalSinceNow < seconds {
            debugPrint("[DATA] do not update \(url) \(seconds) > \(-lastFetch.timeIntervalSinceNow)")
            return (Cache.retrieve(key: url, type: type), .cache)
        } else {
            debugPrint("[DATA] do update \(url) \(seconds) vs \(-lastFetch.timeIntervalSinceNow)")
            let response = await getData(url: url, type: type)
            
            Cache.store(key: dateKey, data: Date.now)
            
            return (response, .api)
        }
    }

    func getData<T : Codable>(url urlString: String, type: T.Type) async -> T? {
        guard let url = URL(string: urlString) else {
            print("[DATA] Your API end point is Invalid")
            return nil
        }
        let request = URLRequest(url: url)
        print("[DATA] GET \(type) from \(url)")
        
        do {
            let (data, _) = try await URLSession.shared.data(for: request)
            let parsed = try apiJsonDecoder.decode(type, from: data)
            Cache.store(key: urlString, data: parsed)
            return parsed
        } catch let error {
            print("[DATA] Failed to retrieve data \(error)")
            return Cache.retrieve(key: urlString, type: type)
        }
    }
    
    func postData<T : Codable & Equatable>(url urlString: String, data: T) async {
        
        guard isNewRequest(data, key: urlString) else {
            print("[DATA] Idempotent \(type(of: data)) Request")
            return
        }
        guard let url = URL(string: urlString) else {
            print("[DATA] Your API end point is Invalid")
            return
        }
        print("[DATA] POST \(data) to \(url)")
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = try! JSONEncoder().encode(data)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            let (_, response) = try await URLSession.shared.data(for: request)
            guard let response = response as? HTTPURLResponse else {
                print("[DATA] error", response)
                return
            }
            guard response.statusCode == 200 else {
                print("[DATA] statusCode should be 200, but is \(response.statusCode)")
                return
            }
            Cache.store(key: urlString, data: data)
        } catch {
            print("[DATA] error", error)
        }
    }
    
    func isNewRequest<T: Codable & Equatable>(_ req: T, key: String) -> Bool {
        guard let lastRequest = Cache.retrieve(key: key, type: T.self) else {
            return true
        }
        return lastRequest != req
    }
}

func getJsonDecoder() -> JSONDecoder {
    let jsonDecoder = JSONDecoder()
    let isoDateFormatter = ISO8601DateFormatter()
    jsonDecoder.dateDecodingStrategy = JSONDecoder.DateDecodingStrategy.custom({ (decoder) -> Date in
        let container = try decoder.singleValueContainer()
        var dateStr = try container.decode(String.self)
        if dateStr.contains(".") {
            dateStr = dateStr.replacingOccurrences(of: "\\.\\d+", with: "", options: .regularExpression)
        }
        return isoDateFormatter.date(from: dateStr)!
    })
    return jsonDecoder
}

struct RuntimeError: Error {
    let message: String

    init(_ message: String) {
        self.message = message
    }

    public var localizedDescription: String {
        return message
    }
}
