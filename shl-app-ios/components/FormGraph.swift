//
//  FormGraph.swift
//  shl-app-ios
//
//  Created by Pål on 2023-02-16.
//

import SwiftUI

struct FormGraph: View {
    @EnvironmentObject var gamesData: GamesData
    
    @State var points: [Int] = []
    var teamCode: String
    var numberOfGames = 10
    var height = 18
    var width = 6
    
    var body : some View {
        Graph(points: self.points, height: self.height, width: self.width)
        .task {
            points = gamesData.getPoints(for: teamCode, numberOfGames: numberOfGames)
        }
    }
}

struct Graph: View {
    var points: [Int]
    var height = 18
    var width = 6
    var monochromeColor: Color?
    
    var body : some View {
        HStack(alignment: .center, spacing: 2) {
            ForEach(values: points.indices) {
                RoundedRectangle(cornerRadius: 3, style: .circular)
                    .frame(width: CGFloat(width), height: CGFloat(max(points[$0] * (height / 3), 3)))
                    .foregroundColor(monochromeColor ?? getColor(points[$0]))
            }
        }.frame(height: CGFloat(height))
    }
    
    func getColor(_ p: Int) -> Color {
        switch (p) {
        case 0: return .red
        case 1: return .orange
        case 2: return .yellow
        case 3: return .green
        default: return .green
        }
    }
}

struct PlayoffGraph: View {
    var points: [Int]
    
    var body : some View {
        HStack(alignment: .center, spacing: 5) {
            ForEach(values: points.indices) { p in
                Group {
                    let c = getCircle(p: points[p])
                    Circle()
                        .fill(c.color)
                        .frame(width: c.radius, height: c.radius)
                }
            }
        }.frame(height: CGFloat(10))
    }
    
    func getCircle(p: Int) -> (radius: CGFloat, color: Color) {
        switch p {
        case 2, 3: return (10, Color(uiColor: .white))
        case 0, 1: return (5, Color(uiColor: .white))
        default: return (5, Color(uiColor: .darkGray))
        }
    }
}

struct FormGraph_Previews: PreviewProvider {
    static var previews: some View {
        let gamesData = GamesData(data: [
            getPlayedGame(t1: "LHF", s1: 3, t2: "TIK", s2: 2),
            getPlayedGame(t1: "LHF", s1: 2, t2: "TIK", s2: 3),
            getPlayedGame(t1: "LHF", s1: 2, t2: "TIK", s2: 3, overtime: true),
            getPlayedGame(t1: "LHF", s1: 2, t2: "TIK", s2: 3),
            getPlayedGame(t1: "LHF", s1: 4, t2: "TIK", s2: 3, overtime: true),
            getPlayedGame(t1: "LHF", s1: 3, t2: "TIK", s2: 2),
            getPlayedGame(t1: "LHF", s1: 2, t2: "TIK", s2: 3),
            getPlayedGame(t1: "LHF", s1: 2, t2: "TIK", s2: 3, overtime: true),
            getPlayedGame(t1: "LHF", s1: 2, t2: "TIK", s2: 3),
            getPlayedGame(t1: "LHF", s1: 4, t2: "TIK", s2: 3, overtime: true)
        ])
        VStack {
            FormGraph(teamCode: "LHF", numberOfGames: 50)
                .frame(width: 300, height: 24)
                .environmentObject(gamesData)
        }
    }
}
