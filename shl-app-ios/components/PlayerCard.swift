//
//  PlayerCard.swift
//  shl-app-ios
//
//  Created by Pål on 2023-11-05.
//

import SwiftUI

struct PlayerCarousel: View {
    var players: [Player]
    var body: some View {
        ScrollView(.horizontal) {
            HStack {
                ForEach(players) { p in
                    PlayerCard(player: p)
                }
            }
        }
    }
}

struct PlayerCard: View {
    var player: Player
    var body: some View {
        ZStack {
            TeamLogo(code: player.team_code, size: 140)
                .blur(radius: 8)
                .offset(y: 0)
                .opacity(0.5)
                .scaleEffect(1.6)
                
            ZStack(alignment: .top) {
                PlayerImage(player: player.id, size: 100, cornerRadius: 5)
                    .padding(.top, 5)
                VStack {
                    Spacer()
                    
                    HStack {
                        
                        VStack(alignment: .leading) {
                            Text("\(String(player.first_name.prefix(1))). \(player.family_name)")
                                .lineLimit(1)
                                .scaledToFit()
                                .minimumScaleFactor(0.6)
                                .truncationMode(.middle)
                            HStack {
                                Text("#\(player.jersey)")
                                    .opacity(0.6)
                                Text("\(player.position)")
                                    .opacity(0.6)
                                Text("\(player.getScore())P")
                            }
                        }
                    }
                    .padding(EdgeInsets(top: 5, leading: 5, bottom: 5, trailing: 5))
                    .frame(width: 110)
                    .background(.thinMaterial)
                }
            }
            
        }
        .font(.system(size: 14, weight: .bold, design: .rounded))
        .frame(width: 110, height: 160)
        .cornerRadius(10)
        .background { RoundedRectangle(cornerRadius: 10, style: .continuous).fill(.white) }
    }
}

#Preview {
    let json = """
[{"id":6284,"first_name":"Arvid","family_name":"Westlin","jersey":20,"team_code":"LHC","position":"RW","season":"Season2023","league":"SHL","type":"Player","+/-":-2,"a":0,"fol":0,"fow":0,"g":0,"hits":0,"pim":0,"sog":2,"sw":0,"toi_s":518,"gp":7},{"id":2427,"first_name":"Lars","family_name":"Johansson","jersey":1,"team_code":"FHC","position":"GK","season":"Season2023","league":"SHL","type":"Goalkeeper","ga":28,"soga":327,"spga":142,"svs":299,"gp":14},{"id":4060,"first_name":"Albin","family_name":"Grewe","jersey":46,"team_code":"DIF","position":"LW","season":"Season2023","league":"HA","type":"Player","+/-":-4,"a":3,"fol":0,"fow":0,"g":2,"hits":23,"pim":12,"sog":19,"sw":0,"toi_s":12238,"gp":14},{"id":6110,"first_name":"Jakub","family_name":"Galvas","jersey":79,"team_code":"MIF","position":"RD","season":"Season2023","league":"SHL","type":"Player","+/-":4,"a":5,"fol":0,"fow":0,"g":1,"hits":3,"pim":8,"sog":16,"sw":0,"toi_s":15926,"gp":17},{"id":2820,"first_name":"Carl","family_name":"Persson","jersey":95,"team_code":"MIF","position":"RW","season":"Season2023","league":"SHL","type":"Player","+/-":1,"a":2,"fol":0,"fow":0,"g":5,"hits":10,"pim":4,"sog":32,"sw":0,"toi_s":16266,"gp":17},{"id":6306,"first_name":"Ludvig","family_name":"Mellgren","jersey":5,"team_code":"AIS","position":"LD","season":"Season2023","league":"HA","type":"Player","+/-":0,"a":0,"fol":0,"fow":0,"g":0,"hits":0,"pim":0,"sog":1,"sw":0,"toi_s":555,"gp":2},{"id":1786,"first_name":"Joel","family_name":"Mustonen","jersey":39,"team_code":"IFB","position":"CE","season":"Season2023","league":"HA","type":"Player","+/-":5,"a":6,"fol":0,"fow":91,"g":6,"hits":5,"pim":6,"sog":21,"sw":0,"toi_s":14606,"gp":16},{"id":1552,"first_name":"Oscar","family_name":"Lindberg","jersey":24,"team_code":"SAIK","position":"CE","season":"Season2023","league":"SHL","type":"Player","+/-":-3,"a":9,"fol":0,"fow":92,"g":4,"hits":20,"pim":21,"sog":31,"sw":0,"toi_s":18148,"gp":16},{"id":4998,"first_name":"Fabian","family_name":"Wagner","jersey":26,"team_code":"LHC","position":"LW","season":"Season2023","league":"SHL","type":"Player","+/-":0,"a":3,"fol":0,"fow":29,"g":0,"hits":0,"pim":2,"sog":6,"sw":0,"toi_s":9174,"gp":17},{"id":4144,"first_name":"Hampus","family_name":"Harlestam","jersey":2,"team_code":"SAIK","position":"CE","season":"Season2023","league":"SHL","type":"Player","+/-":0,"a":0,"fol":0,"fow":6,"g":0,"hits":0,"pim":0,"sog":0,"sw":0,"toi_s":689,"gp":1},{"id":3274,"first_name":"Max","family_name":"Lindholm","jersey":11,"team_code":"SAIK","position":"RW","season":"Season2023","league":"SHL","type":"Player","+/-":2,"a":7,"fol":0,"fow":0,"g":2,"hits":5,"pim":30,"sog":34,"sw":0,"toi_s":15949,"gp":16},{"id":2655,"first_name":"Linus","family_name":"Arnesson","jersey":28,"team_code":"OHK","position":"RD","season":"Season2023","league":"SHL","type":"Player","+/-":2,"a":1,"fol":0,"fow":0,"g":0,"hits":2,"pim":0,"sog":3,"sw":0,"toi_s":2708,"gp":10},{"id":3265,"first_name":"Linus","family_name":"Högberg","jersey":33,"team_code":"FHC","position":"LD","season":"Season2023","league":"SHL","type":"Player","+/-":-7,"a":11,"fol":0,"fow":2,"g":0,"hits":0,"pim":0,"sog":25,"sw":0,"toi_s":20828,"gp":18},{"id":4449,"first_name":"Simon","family_name":"Robertsson","jersey":26,"team_code":"SAIK","position":"LW","season":"Season2023","league":"SHL","type":"Player","+/-":-1,"a":0,"fol":0,"fow":0,"g":0,"hits":1,"pim":2,"sog":2,"sw":0,"toi_s":2429,"gp":4},{"id":5750,"first_name":"Nick","family_name":"Schilkey","jersey":7,"team_code":"IFB","position":"LW","season":"Season2023","league":"HA","type":"Player","+/-":-8,"a":10,"fol":0,"fow":0,"g":5,"hits":4,"pim":33,"sog":37,"sw":0,"toi_s":15451,"gp":16},{"id":6015,"first_name":"Brandon","family_name":"Davidson","jersey":88,"team_code":"RBK","position":"LD","season":"Season2023","league":"SHL","type":"Player","+/-":2,"a":0,"fol":0,"fow":0,"g":0,"hits":7,"pim":2,"sog":2,"sw":0,"toi_s":4212,"gp":6},{"id":6287,"first_name":"Kalle","family_name":"Kratz","jersey":42,"team_code":"MIK","position":"LW","season":"Season2023","league":"HA","type":"Player","+/-":1,"a":0,"fol":0,"fow":2,"g":1,"hits":0,"pim":4,"sog":6,"sw":0,"toi_s":2103,"gp":5},{"id":4612,"first_name":"Filip","family_name":"Larsson","jersey":39,"team_code":"LIF","position":"GK","season":"Season2023","league":"SHL","type":"Goalkeeper","ga":10,"soga":221,"spga":128,"svs":211,"gp":8}]
"""
    let players = try! Cache.decoder.decode([Player].self, from: json.data(using: .utf8)!)
    return PlayerCarousel(players: players)
}
