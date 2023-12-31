//
//  PlayerView.swift
//  shl-app-ios
//
//  Created by Pål on 2023-11-18.
//

import SwiftUI


struct TopPlayerEntry2: View {
    @EnvironmentObject var teams: TeamsData
    
    var rank: Int
    var player: Player
    var attr: (Player) -> String

    var body: some View {
        ZStack {
            HStack {
                Spacer()
                TeamLogo(code: player.team_code, size: 260)
                    .blur(radius: 5)
                    .opacity(0.2)
            }
            HStack(spacing: 16) {
                PointsLabel(val: "\(rank)", nrDigits: 2)
                    .font(.system(size: 16, weight: .heavy, design: .rounded))
                PlayerImage(player: player.id, size: 66)
                VStack(spacing: 3) {
                    HStack {
                        Text("\(player.first_name) \(player.family_name)")
                        Spacer()
                        Text(attr(player))
                            .rounded(size: 16, weight: .heavy)
                        
                    }
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    
                    HStack {
                        TeamLogo(code: player.team_code, size: 16)
                        Text("\(teams.getDisplayCode(player.team_code))")
                        Text("#\(player.jersey)")
                        Text("\(player.position)")
                        Spacer()
                    }
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundColor(Color(uiColor: .secondaryLabel))
                }
            }
        }
        .frame(height: 80)
        .padding(EdgeInsets(top: 20, leading: 10, bottom: 20, trailing: 14))
        .clipped()
        
    }
}

struct PlayerEntry2: View {
    @EnvironmentObject var teams: TeamsData
    
    var rank: Int
    var player: Player
    var attr: (Player) -> String

    var body: some View {
        HStack(spacing: 16) {
            PointsLabel(val: "\(rank)", nrDigits: 2)
                .font(.system(size: 16, weight: .heavy, design: .rounded))
            PlayerImage(player: player.id, size: 46)
            VStack(spacing: 3) {
                HStack {
                    Text("\(player.first_name) \(player.family_name)")
                    Spacer()
                    Text(attr(player))
                        .rounded(size: 16, weight: .heavy)
        
                }
                .font(.system(size: 18, weight: .bold, design: .rounded))
                
                HStack {
                    TeamLogo(code: player.team_code, size: 16)
                    Text("\(teams.getDisplayCode(player.team_code))")
                    Text("#\(player.jersey)")
                    Text("\(player.position)")
                    Spacer()
                }
                .font(.system(size: 15, weight: .bold, design: .rounded))
                .foregroundColor(Color(uiColor: .secondaryLabel))
            }
        }
        .padding(EdgeInsets(top: 20, leading: 10, bottom: 20, trailing: 14))
    }
}

struct SearchPlayerEntry2: View {
    @EnvironmentObject var teams: TeamsData
    
    var player: Player

    var body: some View {
        HStack(spacing: 16) {
            PlayerImage(player: player.id, size: 46)
            VStack(spacing: 3) {
                HStack {
                    Text("\(player.first_name) \(player.family_name)")
                    Spacer()
                    if player.position == "GK" {
                        Text(ListType.mostSavePerc.getAttr()(player))
                            .fontWeight(.bold)
                    } else {
                        Text(ListType.mostPoints.getAttr()(player))
                            .rounded(size: 16, weight: .heavy)
                    }

                }
                .font(.system(size: 18, weight: .bold, design: .rounded))
                
                HStack {
                    TeamLogo(code: player.team_code, size: 16)
                    Text("\(teams.getDisplayCode(player.team_code))")
                    Text("#\(player.jersey)")
                    Text("\(player.position)")
                    Spacer()
                }
                .font(.system(size: 15, weight: .bold, design: .rounded))
                .foregroundColor(Color(uiColor: .secondaryLabel))
            }
        }
        .padding(EdgeInsets(top: 20, leading: 20, bottom: 20, trailing: 20))
    }
}
enum ListType: String, CaseIterable {
    case mostPoints = "PV.Points"
    case mostGoals = "PV.Goals"
    case mostAssists = "PV.Assists"
    case mostDelta = "PV.Plus Minus"
    case mostPims = "PV.Penalty Minutes"
    
    case mostSavePerc = "PV.Save %"
    case mostSaves = "PV.Saves"
    case gaPerGame = "PV.Goals Against Per Game"
    
    func getSorted(players: [Player]) -> [Player] {
        switch self {
        case .mostPoints: return players.getTopPlayers()
        case .mostAssists: return players
                .filter { $0.position != "GK" }
                .sorted { $0.a ?? 0 > $1.a ?? 0 }
        case .mostGoals: return players
                .filter { $0.position != "GK" }
                .sorted { $0.g ?? 0 > $1.g ?? 0 }
        case .mostDelta: return players
                .filter { $0.position != "GK" }
                .sorted { $0.d ?? 0 > $1.d ?? 0 }
        case .mostPims: return players
                .filter { $0.position != "GK" }
                .sorted { $0.pim ?? 0 > $1.pim ?? 0 }
            
        case .gaPerGame: return players
                .filter { $0.position == "GK" }
                .filter { $0.gp >= 4 }
                .sorted { $0.getGoalsAgainsPerGame() < $1.getGoalsAgainsPerGame() }
        case .mostSaves: return players
                .filter { $0.position == "GK" }
                .sorted { $0.svs ?? 0 > $1.svs ?? 0 }
        case .mostSavePerc: return players
                .filter { $0.position == "GK" }
                .filter { $0.gp >= 4 }
                .sorted { $0.getSavesPercentage() > $1.getSavesPercentage() }
        }
    }
    func getAttr() -> (Player) -> String {
        switch self {
        case .mostPoints: return { "\($0.getScore()) P" }
        case .mostAssists: return { "\($0.a ?? 0) A" }
        case .mostGoals: return { "\($0.g ?? 0) G" }
        case .mostDelta: return { $0.getPlusMinus() }
        case .mostPims: return { "\($0.pim ?? 0) PIM" }
            
        case .gaPerGame: return { String(format: "%.2f GA", $0.getGoalsAgainsPerGame()) }
        case .mostSaves: return { "\($0.svs ?? 0) SVS" }
        case .mostSavePerc: return { String(format: "%.0f %%", $0.getSavesPercentage()) }
        }
    }
}

struct PlayerView: View {
    
    @EnvironmentObject var settings: Settings
    
    @AppStorage("standing.league") var league = League.shl
    
    @EnvironmentObject var players: PlayersData
    
    @State var listType = ListType.mostPoints
    @State var selectedPlayer: Player?
    @State var search = ""
    
    var provider: DataProvider?
    
    var body: some View {
        let searching = !search.isEmpty
        let players = if !searching {
            Array(listType
                .getSorted(players: players.data.filter { self.league == $0.league })
                .prefix(20)
                .enumerated())
        } else {
            Array(players.data
                .filter {
                    if let number = Int(search) {
                        return $0.jersey == number
                    } else {
                        return "\($0.first_name) \($0.family_name)".localizedCaseInsensitiveContains(search)
                    }
                }
                .sorted(by: { $0.getScore() > $1.getScore() })
                .prefix(20)
                .enumerated())
        };
        NavigationView {
            ScrollView {
                VStack(spacing: 0) {
                    Picker(selection: $listType) {
                        ForEach(ListType.allCases, id: \.hashValue) { e in
                            Text(LocalizedStringKey(e.rawValue)).tag(e)
                            if e == .mostPims {
                                Divider()
                            }
                        }
                    } label: {
                        Label(LocalizedStringKey(listType.rawValue), systemImage: "chevron.up.chevron.down")
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                    }
                    .disabled(searching)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(EdgeInsets(top: 0, leading: 20, bottom: 16, trailing: 20))
                    .contentShape(Rectangle())

                    GroupedView {
                        if players.isEmpty {
                            Label("No result", systemImage: "magnifyingglass")
                                .font(.system(size: 20, weight: .bold, design: .rounded))
                                .opacity(0.3)
                                .padding(.vertical, 60)
                        }
                        ForEach(players, id: \.element.id) { (i, p) in
                            if searching {
                                Button {
                                    self.selectedPlayer = p
                                } label: {
                                    SearchPlayerEntry2(player: p)
                                        .contentShape(Rectangle())
                                }
                                .buttonStyle(ActiveButtonStyle())
                            } else if i < 3 {
                                Button {
                                    self.selectedPlayer = p
                                } label: {
                                    TopPlayerEntry2(rank: i + 1, player: p, attr: listType.getAttr())
                                        .contentShape(Rectangle())
                                }
                                .buttonStyle(ActiveButtonStyle())
                            } else {
                                Button {
                                    self.selectedPlayer = p
                                } label: {
                                    PlayerEntry2(rank: i + 1, player: p, attr: listType.getAttr())
                                        .contentShape(Rectangle())
                                }
                                .buttonStyle(ActiveButtonStyle())
                            }
                            Divider()
                            
                        }
                    }
                }
                
            }
            .background(Color(UIColor.systemGroupedBackground))
            .searchable(text: $search, prompt: Text("Search player"))
            
            .navigationBarTitle(Text(self.league == .shl ? "SHL" : "HA"))
            .navigationBarItems(leading: Button {
                self.league = self.league == .shl ? .ha : .shl
            } label: {
                Text(self.league == .ha ? "SHL" : "HA")
                    .rounded(size: 16, weight: .semibold)

            }.frame(height: 44))
            .navigationBarItems(trailing: NavigationLink(destination: SettingsView()) {
                Label("Settings", systemImage: "gearshape")
            })
        }
        
        .sheet(item: $selectedPlayer, onDismiss: {
            self.selectedPlayer = nil
        }) { p in
            if #available(iOS 16.0, *) {
                PlayerStatsSheet(player: p)
                    .presentationDetents([.medium, .large])
            } else {
                PlayerStatsSheet(player: p)
            }
        }
        .task(id: settings.season) {
            debugPrint("[PLAYERVIEW] task")
            await reloadData()
        }
    }
    
func reloadData(_ maxAge: TimeInterval = 60 * 3) async {
        if let players = await provider?.getPlayers(for: settings.season, maxAge: maxAge).entries {
            self.players.set(data: players)
        }
    }
}

@available(iOS 17.0, *)
#Preview {
    let json = """
[{"id":6284,"first_name":"Arvid","family_name":"Westlin","jersey":20,"team_code":"LHC","position":"RW","season":"Season2023","league":"SHL","type":"Player","+/-":-2,"a":0,"fol":0,"fow":0,"g":0,"hits":0,"pim":0,"sog":2,"sw":0,"toi_s":518,"gp":7},{"id":2427,"first_name":"Lars","family_name":"Johansson","jersey":1,"team_code":"FHC","position":"GK","season":"Season2023","league":"SHL","type":"Goalkeeper","ga":28,"soga":327,"spga":142,"svs":299,"gp":14},{"id":4060,"first_name":"Albin","family_name":"Grewe","jersey":46,"team_code":"DIF","position":"LW","season":"Season2023","league":"HA","type":"Player","+/-":-4,"a":3,"fol":0,"fow":0,"g":2,"hits":23,"pim":12,"sog":19,"sw":0,"toi_s":12238,"gp":14},{"id":6110,"first_name":"Jakub","family_name":"Galvas","jersey":79,"team_code":"MIF","position":"RD","season":"Season2023","league":"SHL","type":"Player","+/-":4,"a":5,"fol":0,"fow":0,"g":1,"hits":3,"pim":8,"sog":16,"sw":0,"toi_s":15926,"gp":17},{"id":2820,"first_name":"Carl","family_name":"Persson","jersey":95,"team_code":"MIF","position":"RW","season":"Season2023","league":"SHL","type":"Player","+/-":1,"a":2,"fol":0,"fow":0,"g":5,"hits":10,"pim":4,"sog":32,"sw":0,"toi_s":16266,"gp":17},{"id":6306,"first_name":"Ludvig","family_name":"Mellgren","jersey":5,"team_code":"AIS","position":"LD","season":"Season2023","league":"HA","type":"Player","+/-":0,"a":0,"fol":0,"fow":0,"g":0,"hits":0,"pim":0,"sog":1,"sw":0,"toi_s":555,"gp":2},{"id":1786,"first_name":"Joel","family_name":"Mustonen","jersey":39,"team_code":"IFB","position":"CE","season":"Season2023","league":"HA","type":"Player","+/-":5,"a":6,"fol":0,"fow":91,"g":6,"hits":5,"pim":6,"sog":21,"sw":0,"toi_s":14606,"gp":16},{"id":1552,"first_name":"Oscar","family_name":"Lindberg","jersey":24,"team_code":"SAIK","position":"CE","season":"Season2023","league":"SHL","type":"Player","+/-":-3,"a":9,"fol":0,"fow":92,"g":4,"hits":20,"pim":21,"sog":31,"sw":0,"toi_s":18148,"gp":16},{"id":4998,"first_name":"Fabian","family_name":"Wagner","jersey":26,"team_code":"LHC","position":"LW","season":"Season2023","league":"SHL","type":"Player","+/-":0,"a":3,"fol":0,"fow":29,"g":0,"hits":0,"pim":2,"sog":6,"sw":0,"toi_s":9174,"gp":17},{"id":4144,"first_name":"Hampus","family_name":"Harlestam","jersey":2,"team_code":"SAIK","position":"CE","season":"Season2023","league":"SHL","type":"Player","+/-":0,"a":0,"fol":0,"fow":6,"g":0,"hits":0,"pim":0,"sog":0,"sw":0,"toi_s":689,"gp":1},{"id":3274,"first_name":"Max","family_name":"Lindholm","jersey":11,"team_code":"SAIK","position":"RW","season":"Season2023","league":"SHL","type":"Player","+/-":2,"a":7,"fol":0,"fow":0,"g":2,"hits":5,"pim":30,"sog":34,"sw":0,"toi_s":15949,"gp":16},{"id":2655,"first_name":"Linus","family_name":"Arnesson","jersey":28,"team_code":"OHK","position":"RD","season":"Season2023","league":"SHL","type":"Player","+/-":2,"a":1,"fol":0,"fow":0,"g":0,"hits":2,"pim":0,"sog":3,"sw":0,"toi_s":2708,"gp":10},{"id":3265,"first_name":"Linus","family_name":"Högberg","jersey":33,"team_code":"FHC","position":"LD","season":"Season2023","league":"SHL","type":"Player","+/-":-7,"a":11,"fol":0,"fow":2,"g":0,"hits":0,"pim":0,"sog":25,"sw":0,"toi_s":20828,"gp":18},{"id":4449,"first_name":"Simon","family_name":"Robertsson","jersey":26,"team_code":"SAIK","position":"LW","season":"Season2023","league":"SHL","type":"Player","+/-":-1,"a":0,"fol":0,"fow":0,"g":0,"hits":1,"pim":2,"sog":2,"sw":0,"toi_s":2429,"gp":4},{"id":5750,"first_name":"Nick","family_name":"Schilkey","jersey":7,"team_code":"IFB","position":"LW","season":"Season2023","league":"HA","type":"Player","+/-":-8,"a":10,"fol":0,"fow":0,"g":5,"hits":4,"pim":33,"sog":37,"sw":0,"toi_s":15451,"gp":16},{"id":6015,"first_name":"Brandon","family_name":"Davidson","jersey":88,"team_code":"RBK","position":"LD","season":"Season2023","league":"SHL","type":"Player","+/-":2,"a":0,"fol":0,"fow":0,"g":0,"hits":7,"pim":2,"sog":2,"sw":0,"toi_s":4212,"gp":6},{"id":6287,"first_name":"Kalle","family_name":"Kratz","jersey":42,"team_code":"MIK","position":"LW","season":"Season2023","league":"HA","type":"Player","+/-":1,"a":0,"fol":0,"fow":2,"g":1,"hits":0,"pim":4,"sog":6,"sw":0,"toi_s":2103,"gp":5},{"id":4612,"first_name":"Filip","family_name":"Larsson","jersey":39,"team_code":"LIF","position":"GK","season":"Season2023","league":"SHL","type":"Goalkeeper","ga":10,"soga":221,"spga":128,"svs":211,"gp":8}]
"""
    let players = try! Cache.decoder.decode([Player].self, from: json.data(using: .utf8)!)
    return PlayerView()
        .environmentObject(getTeamsData())
        .environmentObject(PlayersData(data: players))
        .environmentObject(Settings())
}
