//
//  VoteView.swift
//  shl-app-ios
//
//  Created by Pål on 2023-06-06.
//

import SwiftUI

func map(minRange:CGFloat, maxRange:CGFloat, minDomain:CGFloat, maxDomain:CGFloat, value:CGFloat) -> CGFloat {
    if maxRange == minRange {
        return minDomain
    }
    return minDomain + (maxDomain - minDomain) * (value - minRange) / (maxRange - minRange)
}


struct PickemStatsView: View {
    @EnvironmentObject var pickemsData: PickemData
    @EnvironmentObject var games: GamesData
    @EnvironmentObject var teams: TeamsData
    
    @State var nrCorrects = 0
    @State var nrPicked = 0
    
    var body: some View {
        let percentage = (Float(nrCorrects) / Float(max(nrPicked, 1))) * 100
        VStack(spacing: 20) {
            HStack(spacing: 40) {
                HStack(alignment: .center, spacing: 0) {
                    Text("🏅").rounded(size: 20, weight: .heavy)
                    PointsLabel(val: "\(nrCorrects)", nrDigits: 3)
                        .font(.system(size: 30, weight: .heavy, design: .rounded))
                    Text("/ \(nrPicked)")
                        .font(.system(size: 15, weight: .heavy, design: .rounded))
                        .foregroundColor(Color(UIColor.quaternaryLabel))
                        .offset(x: 4, y: 3)
                }
                Text("\(String(format: "%.0f", percentage))%")
                    .font(.system(size: 30, weight: .heavy, design: .rounded))
            }
        }
        .onAppear {
            let playedGames = games.getGames().filter { $0.isPlayed() }
            self.nrCorrects = pickemsData.getNrCorrect(playedGames: playedGames)
            self.nrPicked = playedGames.filter { pickemsData.get($0.game_uuid) != nil }.count
        }
        
    }
}

struct GameCard: View {
    var game: Game
    var enabled: Bool
    var onPicked: (_ game: Game, _ teamCode: String) -> Void
    
    @State var offset = CGSize.zero
    
    var body: some View {
        VStack(alignment: .center, spacing: 4) {
            HStack(spacing: 18) {
                TeamAvatar(game.home_team_code, alignment: .trailing)
                GameScore(s1: 0, s2: 0)
                    .opacity(0.2)
                TeamAvatar(game.away_team_code, alignment: .leading)
            }
            HStack(alignment: .center, spacing: 2) {
                Text(LocalizedStringKey(game.start_date_time.getFormattedDate()))
                    .scaledToFit()
                    .minimumScaleFactor(0.6)
                Text("•")
                Text("\(game.start_date_time.getFormattedTime())")
            }
            .font(.system(size: 14, weight: .bold, design: .rounded))
            .foregroundColor(Color(UIColor.secondaryLabel))
        }
        .padding(.vertical, 25).padding(.horizontal, 10)
        .background(RoundedRectangle(cornerRadius: 20)
            .foregroundColor(Color(.secondarySystemGroupedBackground))
            .shadow(radius: 4, y: 3))
        .overlay(RoundedRectangle(cornerRadius: 20)
            .stroke(.gray.opacity(0.3))
            .foregroundColor(.clear))
        .offset(x: self.offset.width)
        .rotationEffect(.degrees(Double(self.offset.width / UIScreen.main.bounds.width) * 15), anchor: .bottom)
        .gesture(
            enabled ? DragGesture().onChanged { e in
                withAnimation(.interactiveSpring()) {
                    self.offset = e.translation
                }
            }.onEnded { e in
                if abs(e.predictedEndTranslation.width) < 200 {
                    withAnimation(.spring()) {
                        self.offset = CGSize.zero
                    }
                } else {
                    let leftSide = e.translation.width < 0
                    self.onPicked(game, leftSide ? game.home_team_code : game.away_team_code)
                    withAnimation(.spring()) {
                        self.offset = CGSize(width: e.predictedEndTranslation.width, height: 0)
                    }
                }
            } : nil )
    }
}

struct GameCardStack: View {
    var games: [Game]
    
    @State var offset = CGSize.zero
    
    var onVoteFor: (_ game: Game, _ teamCode: String) -> Void
    
    var body: some View {
        ZStack {
            ForEach(games.prefix(5), id: \.game_uuid) { (e: Game) in
                let index: Int = games.firstIndex(of: e)!
                let i_d = Double(index)
                let nrGames: CGFloat = 15
                let mapped_scale = CGFloat(1 - i_d * 0.09)
                let mapped_offset = -CGFloat(i_d * 10)
                let mapped_blur = CGFloat((i_d - 1) * 0.6)
                GameCard(game: e, enabled: index == 0, onPicked: self.onVoteFor)
                    .scaleEffect(x: mapped_scale, y: mapped_scale, anchor: .center)
                    .offset(y: mapped_offset)
                    .blur(radius: mapped_blur, opaque: false)
                    .zIndex(Double(nrGames) - i_d)

            }
        }
    }
}

struct PickemView: View {
    @EnvironmentObject var games: GamesData
    @EnvironmentObject var teams: TeamsData
    @EnvironmentObject var starredTeams: StarredTeams
    @EnvironmentObject var settings: Settings
    @EnvironmentObject var pickemData: PickemData
    
    @Binding var isPresent: Bool
    
    @State private var appearAnimationFinished: Bool = false
    
    @State var gamesToVote: [Game] = []
    
    var body: some View {
        VStack {
            ZStack {
                if let game = gamesToVote.first {
                    VStack {
                        HStack(spacing: 100) {
                            TeamLogo(code: game.home_team_code, size: 200)
                                .id(game.home_team_code + game.game_uuid)
                                .transition(.opacity)
                            TeamLogo(code: game.away_team_code, size: 200)
                                .id(game.away_team_code + game.game_uuid)
                                .transition(.opacity)
                        }
                        .offset(y: appearAnimationFinished ? 0 : 150)
                        .blur(radius: 5)
                        .opacity(0.25)
                    }
                }
                
                VStack(spacing: 20) {
                    GameCardStack(games: gamesToVote, onVoteFor: onVoteFor)
                    
                    if gamesToVote.count > 0 {
                        HStack {
                            Image(systemName: "arrow.backward")
                            Text("PICKEM.SWIPE")
                            Image(systemName: "arrow.forward")
                        }
                    } else {
                        Button {
                            withAnimation(.spring()) {
                                self.resetFrom(picks: [:])
                            }
                        } label: { Text("PICKEM.NO_GAMES_LEFT") }
                    }
                }
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundColor(Color(.tertiaryLabel))
                .offset(y: appearAnimationFinished ? 0 : 280)
            }
        }
        .navigationBarTitle("", displayMode: .inline)
        .task {
            self.resetFrom(picks: self.pickemData.getPicksPerGame())
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05, execute: {
                withAnimation(.spring()) {
                    self.appearAnimationFinished = true
                }
            })
        }
        .onDisappear {
            self.appearAnimationFinished = false
        }
    }
    
    func onVoteFor(_ game: Game, _ teamCode: String) {
        withAnimation(.easeInOut) {
            self.gamesToVote.removeAll(where: { $0.game_uuid == game.game_uuid })
            
            if self.gamesToVote.isEmpty {
                self.isPresent = false
            }
        }
        Task {
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            _ = await self.pickemData.vote(gameUuid: game.game_uuid, team: teamCode)
        }
    }
    
    func resetFrom(picks: [String:Pick]) {
        let teamCodes = settings.onlyStarred ? starredTeams.starredTeams : []
        let applicableGames = (games.getGamesToday(teamCodes: teamCodes, starred: starredTeams.starredTeams) +
            games.getFutureGames(teamCodes: teamCodes, starred: starredTeams.starredTeams, includeToday: false))
            .filter { PickemData.isPickable(game: $0) }
            .filter { picks[$0.game_uuid] == nil }
        
        self.gamesToVote = applicableGames
    }
}


struct PickemViewWrapper: View {
    @State var isPresented = false
    var body: some View {
        VStack {
            Button {
                withAnimation {
                    isPresented = true
                }
            } label: {
                Text("Open")
            }
        }
        .sheet(isPresented: $isPresented) {
            PickemView(isPresent: $isPresented)
                .presentationDragIndicator(.visible)
                .presentationDetents([.height(280)])
        }
    }
}

struct PickemView_Previews: PreviewProvider {
    static var previews: some View {
        PickemViewWrapper()
            .environmentObject(getGamesData())
            .environmentObject(getTeamsData())
            .environmentObject(StarredTeams())
            .environmentObject(Settings())
            .environmentObject(getPickemData())
    }
}

struct PickemStatsView_Previews: PreviewProvider {
    static var previews: some View {
        PickemStatsView()
            .environmentObject(getGamesData())
            .environmentObject(getTeamsData())
            .environmentObject(StarredTeams())
            .environmentObject(Settings())
            .environmentObject(getPickemData())
    }
}
