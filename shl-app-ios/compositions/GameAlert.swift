//
//  Banners.swift
//  shl-app-ios
//
//  Created by Pål on 2022-10-23.
//

import SwiftUI

struct GoalAlert: View {
    
    var alert: GameNofitication?
    @State var spacing: CGFloat = 20
    
    var body: some View {
        ZStack {
            Rectangle()
                .fill(Color(UIColor.systemYellow))
            HStack(spacing: spacing) {
                Text("🚨 MÅL!")
                    .font(.system(size: 40, weight: .black, design: .rounded))
                    .foregroundColor(.black)
                    .fixedSize()
                TeamLogo(code: alert?.team ?? "", size: 110)
                    .frame(height: 90, alignment: .center)
                    .clipped()
            }
        }.frame(width: .infinity, height: 90, alignment: .top)
        .onAppear {
         //   withAnimation(.easeOut(duration: 1)) {
         //       self.spacing = 20
         //   }
        }
    }
}

struct TitleAlert: View {

    var alert: GameNofitication?
    @State var offset: CGFloat = 0
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 0)
                .fill(Color(UIColor.systemYellow))
            VStack {
                Text("\(alert?.title ?? "")")
                    .font(.system(size: 18, weight: .black, design: .rounded))
                    .foregroundColor(.black)
                    .offset(x: offset)
                Text("\(alert?.body ?? "")")
                    .font(.system(size: 16, weight: .heavy, design: .rounded))
                    .foregroundColor(.black)
                    .offset(x: -offset)
            }
        }.frame(width: .infinity, height: 80, alignment: .top)
        .onAppear {
        //    withAnimation(.easeOut(duration: 1)) {
        //        self.offset = 0
        //    }
        }
    }
}

struct GameAlert: View {

    var alert: GameNofitication?
    @State var visible: Bool = false
    @State var workItem: DispatchWorkItem?
    
    var body: some View {
        Group {
            if visible {
                switch alert?.type {
                case "Goal": GoalAlert(alert: alert).id((alert?.title ?? "") + (alert?.body ?? ""))
                default: TitleAlert(alert: alert).id((alert?.title ?? "") + (alert?.body ?? ""))
                }
            }
        }
        .transition(.move(edge: .top).combined(with: .opacity))
        .gesture(TapGesture().onEnded { _ in
            withAnimation {
                self.visible = false
            }
        })
        .onChange(of: alert) { old, newAlert in
            withAnimation(.spring()) {
                self.visible = true
            }
            self.workItem?.cancel()
            self.workItem = DispatchWorkItem {
                withAnimation {
                    self.visible = false
                }
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 6, execute: self.workItem!)
        }
        .zIndex(1)
    }
}

struct AlertWrapper: View {
    
    @State var alert: GameNofitication?
    @State var numberGoals = 1
    var body: some View {
        ZStack {
            VStack {
                GameAlert(alert: self.alert)
                Spacer()
            }
            VStack(spacing: 10) {
                Spacer(minLength: 40)
                Text("\(numberGoals)")
                    .font(.system(size: 30, weight: .black, design: .rounded))
                
                Spacer()
                Button("Toggle") {
                    withAnimation {
                        self.numberGoals += 1
                        alert = GameNofitication(team: "LHF", game_uuid: "game_uuid", title: "MÅÅL", body: "LHF \(numberGoals) - 0 FBK", type: "Goal")
                    }
                }
                Button("New Alert") {
                    withAnimation {
                        self.numberGoals += 1
                        alert = GameNofitication(team: nil, game_uuid: "game_uuid_\(numberGoals)", title: "Matchen började", body: "LHF 0 - 0 FBK", type: "GameStarted")
                    }
                }
            }
        }
    }
}

struct Banners_Previews: PreviewProvider {
    
    static var previews: some View {
        AlertWrapper()
    }
}
