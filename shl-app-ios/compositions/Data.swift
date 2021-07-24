//
//  Data.swift
//  HockeyPal
//
//  Created by Pål Forsberg on 2021-01-08.
//

import Foundation
import SwiftUI

let gamesUrl = "https://api.mocki.io/v1/e48f3d0f"
let standingsUrl = "https://api.mocki.io/v1/c1b1266f"
let teamsUrl = "https://api.mocki.io/v1/d066b1b4"


func getGames(completion: @escaping (GamesData) -> ()) {
    getData(url: gamesUrl, type: GamesData.self, completion: completion)
}

func getStandings(completion: @escaping (StandingsData) -> ()) {
    getData(url: standingsUrl, type: StandingsData.self, completion: completion)
}

func getData<T>(url: String, type: T.Type, completion: @escaping (T) -> ()) where T : Codable {
    guard let url = URL(string: url) else {
        print("Your API end point is Invalid")
        return
    }
    let request = URLRequest(url: url)
    print("fetching \(type) from \(url)")
    URLSession.shared.dataTask(with: request) { data, response, error in
        if let data = data {
            do {
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = JSONDecoder.DateDecodingStrategy.iso8601
                let response = try decoder.decode(type, from: data)
                DispatchQueue.main.async {
                    completion(response)
                }
            } catch let error {
                print("error \(error)")
            }
           
        }
    }.resume()
}

struct GamesData: Codable {
    let data: [Game]
    
    func getGames() -> [Game] {
        return data.sorted { (a, b) -> Bool in
            return a.start_date_time < b.start_date_time
        }
    }

    func getLiveGames(teamCodes: [String]) -> [Game] {
        let now = Date()
        return Array(getGames()
            .filter({ game -> Bool in
                return game.start_date_time == now
            })
            .filter(getTeamFilter(teamCodes: teamCodes)))
    }
    
    func getPlayedGames(teamCodes: [String]) -> [Game] {
        let now = Date()
        return Array(getGames()
            .sorted { (a, b) -> Bool in
                return a.start_date_time > b.start_date_time
            }
            .filter({ game -> Bool in
                return game.start_date_time < now
            })
            .filter(getTeamFilter(teamCodes: teamCodes)))
    }
    
    func getFutureGames(teamCodes: [String]) -> [Game] {
        let now = Date()
        return Array(getGames()
            .filter({ game -> Bool in
                return game.start_date_time > now
            })
            .filter(getTeamFilter(teamCodes: teamCodes))
            .prefix(5))
    }
    
    func getTeamFilter(teamCodes: [String]) -> (Game) -> Bool {
        if (teamCodes.isEmpty) {
            return { game in return true }
        }
        
        return { game in teamCodes.contains { (e) -> Bool in
            return game.hasTeam(e)
        }}
    }
}

struct Game: Codable, Identifiable  {
    var id: Int {
        return game_id
    }
    let game_id: Int
    let away_team_code: String
    let away_team_result: Int
    let home_team_code: String
    let home_team_result: Int
    let start_date_time: Date
    let played: Bool
    
    func hasTeam(_ teamCode: String) -> Bool {
        return away_team_code == teamCode || home_team_code == teamCode
    }
}

struct StandingsData: Codable {
    let data: [Standing]
}

struct Standing: Codable, Identifiable {
    var id: String {
        return team_code
    }
    let team_code: String
    let diff: Int
    let gp: Int
    let rank: Int
    let points: Int
    
    func getPointsPerGame() -> Double {
        return Double(points) / Double(gp)
    }
}

struct TeamsData: Codable {
    let data: [Team]
}
struct Team: Codable, Identifiable {
    var id: String {
        return code
    }
    let code: String
    let name: String
}

extension Date {
   func getFormattedDateAndTime() -> String {
        let dateformat = DateFormatter()
        
        dateformat.locale = Locale.current
        let dateDelta = Date.daysBetween(from: Date(), to: self)
    
        if (dateDelta < 1) {
            dateformat.doesRelativeDateFormatting = true
            dateformat.dateStyle = .short
            dateformat.timeStyle = .short
        } else if (dateDelta < 7) {
            dateformat.dateFormat = "E HH:mm"
        } else {
            dateformat.dateFormat = "dd/MM HH:mm"
        }
        return dateformat.string(from: self)
    }
    
    func getFormattedDate() -> String {
         let dateformat = DateFormatter()
         
         dateformat.locale = Locale.current
         let dateDelta = Date.daysBetween(from: Date(), to: self)
     
         if (dateDelta < 1) {
             dateformat.doesRelativeDateFormatting = true
             dateformat.dateStyle = .short
         } else if (dateDelta < 7) {
             dateformat.dateFormat = "E"
         } else {
             dateformat.dateFormat = "dd/MM"
         }
         return dateformat.string(from: self)
     }
    
    
    func getFormattedTime() -> String {
        let dateformat = DateFormatter()
        dateformat.locale = Locale.current
        dateformat.dateFormat = "HH:mm"
        return dateformat.string(from: self)
     }
    
    static func daysBetween(from: Date, to: Date) -> Int {
        return Calendar.current.dateComponents([.day], from: from, to: to).day!
    }
}
