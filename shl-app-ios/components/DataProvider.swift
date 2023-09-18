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
let baseUrl = "https://palsserver.com/shl-api/v2"
#endif
let gamesUrl = { (season: Int) -> String in return "\(baseUrl)/games/\(season)" }
let standingsUrl = { (season: Int) -> String in return "\(baseUrl)/standings/\(season)" }
let teamsUrl = "\(baseUrl)/teams"
let playoffUrl = { (season: Int) -> String in "\(baseUrl)/playoffs/\(season)" }
let userUrl = "\(baseUrl)/user"
let liveActivityStartUrl = "\(baseUrl)/live-activity/start"
let liveActivityEndUrl = "\(baseUrl)/live-activity/end"
let gameDetailsUrl = { (game_uuid: String) -> String in return "\(baseUrl)/game/\(game_uuid)" }
let playersUrl = { (season: Int, code: String) -> String in "\(baseUrl)/players/\(season)/\(code)" }
let picksUrl = "\(baseUrl)/vote"

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
    
    func getStandings(season: Int, fetchType: GetType = .throttled, maxAge seconds: TimeInterval = 10) async -> (entries: StandingRsp?, type: GetType) {
        let url = standingsUrl(season)
        let type = StandingRsp.self
        switch fetchType {
        case .throttled: return await getThrottledData(url: url, type: type, maxAge: seconds)
        case .cache: return (Cache.retrieve(key: url, type: type), fetchType)
        case .api: return (await getData(url: url, type: type), fetchType)
        }
    }
    
    func getCachedStandings(season: Int) -> StandingRsp? {
        return Cache.retrieve(key: standingsUrl(season), type: StandingRsp.self)
    }
    
    func getGameDetails(game_uuid: String) async -> GameDetails? {
        return await getData(url: gameDetailsUrl(game_uuid), type: GameDetails.self)
    }
    
    func getTeams() async -> [Team]? {
        if let cached = Cache.retrieve(key: teamsUrl, type: [Team].self) {
            return cached
        }
        return await getData(url: teamsUrl, type: [Team].self)
    }
    
    func getCachedTeams() -> [Team]? {
        return Cache.retrieve(key: teamsUrl, type: [Team].self)
    }
    
    func getPlayoffs(season: Int, maxAge: TimeInterval) async -> (entries: PlayoffRsp?, type: GetType) {
        return await getThrottledData(url: playoffUrl(season), type: PlayoffRsp.self, maxAge: maxAge)
    }
    
    func getCachedPlayoffs(season: Int) -> PlayoffRsp? {
        return Cache.retrieve(key: playoffUrl(season), type: PlayoffRsp.self)
    }
    
    func getPlayers(for season: Int, code: String) async -> [Player]? {
        return await getThrottledData(url: playersUrl(season, code), type: [Player].self, maxAge: 10).entries
    }
    
    func getStatus() async -> Status? {
        return await getThrottledData(url: "\(baseUrl)/status", type: StatusRsp.self, maxAge: 120).entries?.status
    }
    
    func addUser(request: AddUser) async {
        do {
            _ = try await postData(url: userUrl, data: request)
        } catch {
            
        }
    }
    
    func startLiveActivity(_ request: StartLiveActivity) async {
        do {
            _ = try await postData(url: liveActivityStartUrl, data: request)
        } catch {
            
        }
    }
    
    func endLiveActivity(_ request: EndLiveActivity) async {
        do {
            _ = try await postData(url: liveActivityEndUrl, data: request, idempotencyCheck: false)
        } catch {
            
        }
    }
    
    func pick(_ request: PickReq) async throws -> VotesPerGame? {
        try await postData(url: picksUrl, data: request, type: VotesPerGame.self, idempotencyCheck: false)
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
            print("[DATA] Failed to retrieve data \(urlString) \(error)")
            return Cache.retrieve(key: urlString, type: type)
        }
    }
    
    enum PostError: Error {
        case parse
        case statusCode
    }
    
    func postData<T : Codable, R : Codable>(url urlString: String, data: T, type: R.Type, idempotencyCheck: Bool = true) async throws -> R? where T : Equatable {
        if let data = try await postData(url: urlString, data: data, idempotencyCheck: idempotencyCheck) {
            return try apiJsonDecoder.decode(type, from: data)
        }
        return nil
    }
    
    func postData<T : Codable>(url urlString: String, data: T, idempotencyCheck: Bool = true) async throws -> Data? where T : Equatable {
        guard isNewRequest(data, key: urlString) || !idempotencyCheck else {
            print("[DATA] Idempotent \(data.self) Request")
            return nil
        }
        guard let url = URL(string: urlString) else {
            print("[DATA] Your API end point is Invalid")
            return nil
        }
        print("[DATA] POST \(data) to \(url)")
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = try! JSONEncoder().encode(data)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(API_KEY, forHTTPHeaderField: "x-api-key")
        
        do {
            let (rspData, response) = try await URLSession.shared.data(for: request)
            guard let response = response as? HTTPURLResponse else {
                print("[DATA] error", response)
                throw PostError.parse
            }
            guard response.statusCode == 200 else {
                print("[DATA] statusCode should be 200, but is \(response.statusCode)")
                throw PostError.statusCode
            }
            if idempotencyCheck {
                Cache.store(key: urlString, data: data)
            }
            return rspData
        } catch {
            print("[DATA] error", error)
            throw error
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
