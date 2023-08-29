//
//  PickemData.swift
//  shl-app-ios
//
//  Created by Pål on 2023-06-27.
//
import Foundation


struct Pick: Codable {
    let gameUuid: String
    var pickedTeam: String
}

private let PICKS_KEY = "picks.\(Settings.currentSeason)"
class PickemData: ObservableObject {
    private let user_id: String
    private let provider: DataProvider?
    var errorHandler: ErrorHandler?
    
    private var picksPerGame: [String: Pick]
    private var picksInFlight: [String: Pick]
    
    init(user_id: String, provider: DataProvider?, errorHandler: ErrorHandler?) {
        debugPrint("[PICKEM] Init")
        self.user_id = user_id
        self.provider = provider
        self.errorHandler = errorHandler
        
        self.picksInFlight = [:]
        self.picksPerGame = [:]
        
        PickemData.readStoredPicks(key: PICKS_KEY).forEach { p in
            self.picksPerGame[p.gameUuid] = Pick(gameUuid: p.gameUuid, pickedTeam: p.pickedTeam)
        }
    }
    
    func get(_ gameUuid: String) -> Pick? {
        self.picksInFlight[gameUuid] ?? self.picksPerGame[gameUuid]
    }
    
    func getPicksPerGame() -> [String:Pick] {
        self.picksPerGame
    }
    
    func vote(gameUuid: String, team: String) async -> VotesPerGame? {
        self.picksInFlight[gameUuid] = Pick(gameUuid: gameUuid, pickedTeam: team)
        self.objectWillChange.send()
        var result: VotesPerGame? = nil
        do {
            result = try await self.provider?.pick(PickReq(game_uuid: gameUuid, user_id: self.user_id, team_code: team))
            self.picksPerGame[gameUuid] = Pick(gameUuid: gameUuid, pickedTeam: team)
            PickemData.updateStored(key: PICKS_KEY, picks: Array(self.picksPerGame.values))
        } catch {
            self.errorHandler?.set(error: "PICKEM.SYNCERROR")
        }
        self.picksInFlight.removeValue(forKey: gameUuid)
        
        DispatchQueue.main.async {
            self.objectWillChange.send()
        }
        
        return result
    }
    
    func isPicked(gameUuid: String, team: String) -> Bool {
        picksPerGame[gameUuid]?.pickedTeam == team
    }
    
    func getPicked(gameUuid: String) -> String? {
        get(gameUuid)?.pickedTeam
    }
    
    func getNrCorrect(playedGames: [Game]) -> Int {
        playedGames.reduce(0) { partialResult, g in
            var isCorrect = false
            if let pick = self.picksPerGame[g.game_uuid] {
                isCorrect = pick.pickedTeam == g.getWinner()
            }
            return partialResult + (isCorrect ? 1 : 0)
        }
    }
    
    static func isPickable(game: Game) -> Bool {
        game.isFuture() &&
        !game.isTbd() &&
        !game.isPlayoff() &&
        !game.isDemotion()
    }
    
    private static let STORAGE = UserDefaults.shared
    private static let PICKS_SEPARATOR = "::"
    
    public static func updateStored(key: String, picks: [Pick]) {
        let pickStrings: [String] = picks.map { "\($0.gameUuid)\(PICKS_SEPARATOR)\($0.pickedTeam)"}
        STORAGE.setValue(pickStrings, forKey: key)
    }
    
    private static func readStoredPicks(key: String) -> [Pick] {
        let pickStrings = STORAGE.stringArray(forKey: key)
        return pickStrings?.map {
            let parts = $0.components(separatedBy: PICKS_SEPARATOR)
            return Pick(gameUuid: parts[0], pickedTeam: parts[1])
        } ?? []
    }
}
