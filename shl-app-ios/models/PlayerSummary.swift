//
//  PlayerSummary.swift
//  shl-app-ios
//
//  Created by Pål on 2025-05-03.
//
import Foundation

struct PlayerSummary: Codable, Hashable {
    var id: Int
    var first_name: String
    var last_name: String
    var uuid: String?
    var height: UInt16?
    var weight: UInt16?
    var date_of_birth: String?
    var nationality: String?
    
    func getAge() -> Int? {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withFullDate]
        let date = formatter.date(from: date_of_birth ?? "")
        if let d = date {
            let calendar = Calendar.current

            let ageComponents = calendar.dateComponents([.year], from: d, to: Date())
            if let age = ageComponents.year {
                return age
            }
        }
        return nil
    }
    
    func getFlag() -> String? {
        switch nationality {
        case "SE": return "🇸🇪" // Sweden
        case "FI": return "🇫🇮" // Finland
        case "NO": return "🇳🇴" // Norway
        case "DK": return "🇩🇰" // Denmark
        case "IS": return "🇮🇸" // Iceland
        case "US": return "🇺🇸" // United States
        case "CA": return "🇨🇦" // Canada
        case "GB": return "🇬🇧" // United Kingdom
        case "DE": return "🇩🇪" // Germany
        case "FR": return "🇫🇷" // France
        case "ES": return "🇪🇸" // Spain
        case "IT": return "🇮🇹" // Italy
        case "NL": return "🇳🇱" // Netherlands
        case "BE": return "🇧🇪" // Belgium
        case "CH": return "🇨🇭" // Switzerland
        case "AT": return "🇦🇹" // Austria
        case "AU": return "🇦🇺" // Australia
        case "NZ": return "🇳🇿" // New Zealand
        case "JP": return "🇯🇵" // Japan
        case "CN": return "🇨🇳" // China
        case "KR": return "🇰🇷" // South Korea
        case "SK": return "🇸🇰"
        case "CZ": return "🇨🇿"
        default:
            return nationality
        }
    }
}
