//
//  PlayerCard.swift
//  shl-app-ios
//
//  Created by Pål on 2023-11-05.
//

import SwiftUI

@available(iOS 18.0, *)
struct PlayerCarousel: View {
    var players: [Player]
    @State var selectedPlayer: Player?
    @State var flipped: Bool = false
    @Namespace var ns
    
    var body: some View {
        ZStack {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 20) {
                    ForEach(players) { p in
                        PlayerCard(player: p, ns: ns)
                        
                            .onTapGesture {
                                withAnimation(.spring(duration: 0.6)) {
                                    self.selectedPlayer = p
                                }
                            }
                            .onAppear {
                            }
                    }
                }
                .padding(.vertical, 20)
            }
            .scrollTargetBehavior(.paging)
            .contentMargins(.horizontal, 20, for: .scrollContent)
            if let p = selectedPlayer {
                ZStack {
                    Rectangle()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .onTapGesture {
                            withAnimation(.spring(duration: 0.6)) {
                                self.selectedPlayer = nil
                                self.flipped = false
                            }
                        }
                        .background(.ultraThinMaterial)
                        .ignoresSafeArea()
                    
                    PlayerCardExpanded(player: p, ns: ns)
                }
            }
        }
    }
}

struct PlayerCard: View {
    var player: Player
    
    var ns: Namespace.ID
    
    var body: some View {
        ZStack {
            VStack(spacing: -2) {
                PlayerImage(player: "\(player.id)", size: 98, cornerRadius: 2)
                    .matchedGeometryEffect(id: "p-img-\(player.id)", in: ns)
    
                PlayerImage(player: "\(player.id)", size: 98, cornerRadius: 0)
                    .matchedGeometryEffect(id: "p-bk-\(player.id)", in: ns)
                    .blur(radius: 10)
                    .scaleEffect(x: 1, y: -1)
            }
            .frame(height: 150, alignment: .top)
            VStack(spacing: 0) {
                Spacer()
                VStack(spacing: -2) {
                    HStack {
                        Text("\(String(player.first_name.prefix(1))). \(player.family_name)")
                            .lineLimit(1)
                            .scaledToFit()
                            .minimumScaleFactor(0.6)
                            .truncationMode(.middle)
                    }
                    .frame(maxWidth: .infinity)
                    
                    HStack {
                        TeamLogo(code: player.team_code, size: 18)
                        Text("\(player.position)")
                            .foregroundColor(Color(uiColor: .tertiaryLabel))
                        if player.position == "GK" {
                            Text(String(format: "%.0f%%", player.getSavesPercentage()))
                        } else {
                            Text("\(player.getPoints())P")
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.bottom, 2)
                }
                .background(.ultraThinMaterial)
            }
            
        }
        .padding(.vertical, 5)
        .padding(.horizontal, 5)
        .font(.system(size: 14, weight: .bold, design: .rounded).lowercaseSmallCaps())
        .frame(width: 100, height: 150)
        .background(.thinMaterial)
        .cornerRadius(4)
        .overlay { RoundedRectangle(cornerRadius: 4).stroke(lineWidth: 2).fill(Color(uiColor: .tertiarySystemFill))}
        .scaleEffect(CGSize(width: 1, height: 1))
        .rotation3DEffect(.degrees(20), axis: (x: 0, y: 0, z: 0))
    }
}

struct PlayerCardExpanded: View {
    var player: Player
    
    var ns: Namespace.ID
    
    var body: some View {
        HStack {
            VStack(spacing: -2) {
                PlayerImage(player: "\(player.id)", size: 120, cornerRadius: 2)
                    .matchedGeometryEffect(id: "p-img-\(player.id)", in: ns)
                PlayerImage(player: "\(player.id)", size: 98, cornerRadius: 0)
                    .matchedGeometryEffect(id: "p-bk-\(player.id)", in: ns)
                    .blur(radius: 10)
                    .scaleEffect(x: 1, y: -1)
            }
            .frame(height: 150, alignment: .top)
            VStack(spacing: 0) {
                VStack(spacing: -2) {
                    HStack {
                        Text("\(String(player.first_name.prefix(1))). \(player.family_name)")
                            .lineLimit(1)
                            .scaledToFit()
                            .minimumScaleFactor(0.6)
                            .truncationMode(.middle)
                    }
                    
                    HStack {
                        TeamLogo(code: player.team_code, size: 18)
                        Text("\(player.position)")
                            .foregroundColor(Color(uiColor: .tertiaryLabel))
                        if player.position == "GK" {
                            Text(String(format: "%.0f%%", player.getSavesPercentage()))
                        } else {
                            Text("\(player.getPoints())P")
                        }
                    }
                    .padding(.bottom, 2)
                }
                .background(.ultraThinMaterial)
            }
            
        }
        .padding(.vertical, 5)
        .padding(.horizontal, 5)
        .font(.system(size: 14, weight: .bold, design: .rounded).lowercaseSmallCaps())
        .background(.thinMaterial)
        .cornerRadius(4)
        .overlay { RoundedRectangle(cornerRadius: 4).stroke(lineWidth: 2).fill(Color(uiColor: .tertiarySystemFill))}
    }
}

@available(iOS 18.0, *)
struct GameStatsPlayerView: View {
    let players: [Player]
    @State var playersToShow: [Player] = []
    var body: some View {
        PlayerCarousel(players: playersToShow)
            .onAppear {
                self.playersToShow = Array(players.sorted { p1, p2 in
                    p1.getScore() > p2.getScore()
                }
                .prefix(6))
            }
    }
}

@available(iOS 18.0, *)
#Preview {
    let json = """
[{"id":6284,"first_name":"Arvid","family_name":"Westlin","jersey":20,"team_code":"LHC","position":"RW","season":"Season2023","league":"SHL","type":"Player","+/-":-2,"a":0,"fol":0,"fow":0,"g":0,"hits":0,"pim":0,"sog":2,"sw":0,"toi_s":518,"gp":7},{"id":2427,"first_name":"Lars","family_name":"Johansson","jersey":1,"team_code":"FHC","position":"GK","season":"Season2023","league":"SHL","type":"Goalkeeper","ga":28,"soga":327,"spga":142,"svs":299,"gp":14},{"id":4060,"first_name":"Albin","family_name":"Grewe","jersey":46,"team_code":"DIF","position":"LW","season":"Season2023","league":"HA","type":"Player","+/-":-4,"a":3,"fol":0,"fow":0,"g":2,"hits":23,"pim":12,"sog":19,"sw":0,"toi_s":12238,"gp":14},{"id":6110,"first_name":"Jakub","family_name":"Galvas","jersey":79,"team_code":"MIF","position":"RD","season":"Season2023","league":"SHL","type":"Player","+/-":4,"a":5,"fol":0,"fow":0,"g":1,"hits":3,"pim":8,"sog":16,"sw":0,"toi_s":15926,"gp":17},{"id":2820,"first_name":"Carl","family_name":"Persson","jersey":95,"team_code":"MIF","position":"RW","season":"Season2023","league":"SHL","type":"Player","+/-":1,"a":2,"fol":0,"fow":0,"g":5,"hits":10,"pim":4,"sog":32,"sw":0,"toi_s":16266,"gp":17},{"id":6306,"first_name":"Ludvig","family_name":"Mellgren","jersey":5,"team_code":"AIS","position":"LD","season":"Season2023","league":"HA","type":"Player","+/-":0,"a":0,"fol":0,"fow":0,"g":0,"hits":0,"pim":0,"sog":1,"sw":0,"toi_s":555,"gp":2},{"id":1786,"first_name":"Joel","family_name":"Mustonen","jersey":39,"team_code":"IFB","position":"CE","season":"Season2023","league":"HA","type":"Player","+/-":5,"a":6,"fol":0,"fow":91,"g":6,"hits":5,"pim":6,"sog":21,"sw":0,"toi_s":14606,"gp":16},{"id":1552,"first_name":"Oscar","family_name":"Lindberg","jersey":24,"team_code":"SAIK","position":"CE","season":"Season2023","league":"SHL","type":"Player","+/-":-3,"a":9,"fol":0,"fow":92,"g":4,"hits":20,"pim":21,"sog":31,"sw":0,"toi_s":18148,"gp":16},{"id":4998,"first_name":"Fabian","family_name":"Wagner","jersey":26,"team_code":"LHC","position":"LW","season":"Season2023","league":"SHL","type":"Player","+/-":0,"a":3,"fol":0,"fow":29,"g":0,"hits":0,"pim":2,"sog":6,"sw":0,"toi_s":9174,"gp":17},{"id":4144,"first_name":"Hampus","family_name":"Harlestam","jersey":2,"team_code":"SAIK","position":"CE","season":"Season2023","league":"SHL","type":"Player","+/-":0,"a":0,"fol":0,"fow":6,"g":0,"hits":0,"pim":0,"sog":0,"sw":0,"toi_s":689,"gp":1},{"id":3274,"first_name":"Max","family_name":"Lindholm","jersey":11,"team_code":"SAIK","position":"RW","season":"Season2023","league":"SHL","type":"Player","+/-":2,"a":7,"fol":0,"fow":0,"g":2,"hits":5,"pim":30,"sog":34,"sw":0,"toi_s":15949,"gp":16},{"id":2655,"first_name":"Linus","family_name":"Arnesson","jersey":28,"team_code":"OHK","position":"RD","season":"Season2023","league":"SHL","type":"Player","+/-":2,"a":1,"fol":0,"fow":0,"g":0,"hits":2,"pim":0,"sog":3,"sw":0,"toi_s":2708,"gp":10},{"id":3265,"first_name":"Linus","family_name":"Högberg","jersey":33,"team_code":"FHC","position":"LD","season":"Season2023","league":"SHL","type":"Player","+/-":-7,"a":11,"fol":0,"fow":2,"g":0,"hits":0,"pim":0,"sog":25,"sw":0,"toi_s":20828,"gp":18},{"id":4449,"first_name":"Simon","family_name":"Robertsson","jersey":26,"team_code":"SAIK","position":"LW","season":"Season2023","league":"SHL","type":"Player","+/-":-1,"a":0,"fol":0,"fow":0,"g":0,"hits":1,"pim":2,"sog":2,"sw":0,"toi_s":2429,"gp":4},{"id":5750,"first_name":"Nick","family_name":"Schilkey","jersey":7,"team_code":"IFB","position":"LW","season":"Season2023","league":"HA","type":"Player","+/-":-8,"a":10,"fol":0,"fow":0,"g":5,"hits":4,"pim":33,"sog":37,"sw":0,"toi_s":15451,"gp":16},{"id":6015,"first_name":"Brandon","family_name":"Davidson","jersey":88,"team_code":"RBK","position":"LD","season":"Season2023","league":"SHL","type":"Player","+/-":2,"a":0,"fol":0,"fow":0,"g":0,"hits":7,"pim":2,"sog":2,"sw":0,"toi_s":4212,"gp":6},{"id":6287,"first_name":"Kalle","family_name":"Kratz","jersey":42,"team_code":"MIK","position":"LW","season":"Season2023","league":"HA","type":"Player","+/-":1,"a":0,"fol":0,"fow":2,"g":1,"hits":0,"pim":4,"sog":6,"sw":0,"toi_s":2103,"gp":5},{"id":4612,"first_name":"Filip","family_name":"Larsson","jersey":39,"team_code":"LIF","position":"GK","season":"Season2023","league":"SHL","type":"Goalkeeper","ga":10,"soga":221,"spga":128,"svs":211,"gp":8}]
"""
    let players = try! Cache.decoder.decode([Player].self, from: json.data(using: .utf8)!)
    return PlayerCarousel(players: players)
}
