//
//  UpdateReportView.swift
//  shl-app-ios
//
//  Created by Pål on 2023-11-30.
//

import SwiftUI

#if DEBUG

struct UpdateReport : Codable, Equatable {
    var game_uuid: String

    var gametime: String
    var status: GameStatus

    var home_team_result: Int
    var away_team_result: Int

    var overtime: Bool
    var shootout: Bool
}

struct AreYouSureButton: View {
    var text: String
    var action: () -> Void
    
    
    @State var areYouSure = false
    
    var body: some View {
        Button {
            if self.areYouSure {
                action()
                self.areYouSure = false
            } else {
                self.areYouSure = true
            }
        } label: {
            if self.areYouSure {
                Text("Säker?")
            } else {
                Text(text)
            }
        }
        .buttonStyle(.bordered)
        .cornerRadius(6)
    }
}

struct UpdateReportView: View {
    
    @EnvironmentObject var errorHandler: ErrorHandler
    
    var game: Game

    @State var req: UpdateReport
    
    init(game: Game) {
        self.game = game
        self._req = State(initialValue: UpdateReport(game_uuid: game.game_uuid,
                                gametime: game.gametime ?? "00:00",
                                status: game.getStatus() ?? GameStatus.period1,
                                home_team_result: game.home_team_result,
                                away_team_result: game.away_team_result,
                                overtime: game.overtime,
                                shootout: game.shootout))
    }
    
    var body: some View {
        VStack {

            HStack {
                TeamAvatar(game.home_team_code)
                TextField("Home Score", value: $req.home_team_result, format: .number)
                    .keyboardType(.numberPad)
                    .font(.system(size: 26, weight: .bold, design: .rounded))
                    .multilineTextAlignment(.center)
                    .padding()
                Text(":")
                TextField("Away Score", value: $req.away_team_result, format: .number)
                    .keyboardType(.numberPad)
                    .multilineTextAlignment(.center)
                    .padding()
                    .font(.system(size: 26, weight: .bold, design: .rounded))
                TeamAvatar(game.away_team_code)
            }
            TextField("Game Time", text: $req.gametime)
                .keyboardType(.numbersAndPunctuation)
                .multilineTextAlignment(.center)
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .padding()
            Picker("Game Status", selection: $req.status) {
                ForEach(GameStatus.allCases, id: \.rawValue) { option in
                    Text(option.rawValue).tag(option)
                }
            }
            Spacer(minLength: 10)
            VStack {
                Toggle("Overtime", isOn: $req.overtime)
                Toggle("Shootout", isOn: $req.shootout)
            }
            .padding(.horizontal, 50)
            Spacer(minLength: 100)
            AreYouSureButton(text: "Skicka") {
                Task {
                    await submit()
                    UIImpactFeedbackGenerator(style: .heavy)
                        .impactOccurred()
                }
            }
            Spacer(minLength: 50)
            
            HStack(spacing: 50) {
                AreYouSureButton(text: "Pausa") {
                    Task {
                        await pause()
                        UIImpactFeedbackGenerator(style: .heavy)
                            .impactOccurred()
                    }
                }
                
                AreYouSureButton(text: "Upausa") {
                    Task {
                        await unpause()
                        UIImpactFeedbackGenerator(style: .heavy)
                            .impactOccurred()
                    }
                }
            }
        }
        .padding()
    }
    
    func submit() async {
        await postData(url: "https://palsserver.com/shl-api/v2/update-report", data: req)
    }
    
    func pause() async {
        await post(url: "https://palsserver.com/shl-api/v2/game/pause")
    }
    
    func unpause() async {
        await post(url: "https://palsserver.com/shl-api/v2/game/unpause")
    }
    
    
    func postData<T : Codable>(url urlString: String, data: T, idempotencyCheck: Bool = true) async where T : Equatable {
        guard let url = URL(string: urlString) else {
            print("[DATA] Your API end point is Invalid")
            return
        }
        print("[DATA] POST \(data) to \(url)")
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = try! JSONEncoder().encode(data)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(API_ADMIN_KEY, forHTTPHeaderField: "x-admin-key")
        
        do {
            let (_, response) = try await URLSession.shared.data(for: request)
            guard let response = response as? HTTPURLResponse else {
                print("[DATA] error", response)
                errorHandler.set(error: "Got parseError \(response)")
                return
            }
            guard response.statusCode == 200 else {
                print("[DATA] statusCode should be 200, but is \(response.statusCode)")
                errorHandler.set(error: "Got statusCode \(response.statusCode)")
                return
            }
            return
        } catch {
            print("[DATA] error", error)
            errorHandler.set(error: "Error \(error)")
        }
        return
    }
    
    func post(url urlString: String, idempotencyCheck: Bool = true) async {
        guard let url = URL(string: urlString) else {
            print("[DATA] Your API end point is Invalid")
            return
        }
        print("[DATA] POST to \(url)")
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(API_ADMIN_KEY, forHTTPHeaderField: "x-admin-key")
        
        do {
            let (_, response) = try await URLSession.shared.data(for: request)
            guard let response = response as? HTTPURLResponse else {
                print("[DATA] error", response)
                errorHandler.set(error: "Got parseError \(response)")
                return
            }
            guard response.statusCode == 200 else {
                print("[DATA] statusCode should be 200, but is \(response.statusCode)")
                errorHandler.set(error: "Got statusCode \(response.statusCode)")
                return
            }
            return
        } catch {
            print("[DATA] error", error)
            errorHandler.set(error: "Error \(error)")
        }
        return
    }
}

#Preview {
    UpdateReportView(game: getLiveGame())
        .environmentObject(getTeamsData())
        .environmentObject(StarredTeams())
        .environmentObject(ErrorHandler())
}

#endif
