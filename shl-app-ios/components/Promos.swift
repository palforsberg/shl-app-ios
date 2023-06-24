//
//  Promos.swift
//  shl-app-ios
//
//  Created by Pål on 2023-05-27.
//

import SwiftUI



struct WidgetPromo: View {
    @AppStorage("widget.promo.2023.removed.7")
    var removed = false
    
    var body: some View {
        if !removed {
            GroupedView {
                ZStack {
                    Group {
                        GeometryReader { geo in
                            Puck(geo: geo, scale: 0.15).pos(0.9, 0.2)
                            Puck(geo: geo, scale: 0.15).pos(0.85, 0.6)
                            Puck(geo: geo, scale: 0.15).pos(0.95, 0.8)
                        }
                    }
                    HStack(spacing: 15) {
                        Image(uiImage: UIImage(named: "TeamWidget")!)
                            .resizable()
                            .scaledToFit()
                            .rotation3DEffect(.degrees(10), axis: (x: 0.0, y: 1.0, z: 0.0))
                            .frame(width: 80)
                        VStack(alignment: .leading, spacing: 5) {
                            Text("Pucken Widgets!")
                                .font(.system(size: 18, weight: .heavy, design: .rounded))
                            Text("WIDGETPROMO.BODY")
                                .font(.system(size: 14, weight: .heavy, design: .rounded))
                        }
                        Spacer()
                        Button(action: {
                            print("Remove WidgetPromo")
                            withAnimation {
                                removed = true
                            }
                        }, label: {
                            Image(systemName: "xmark")
                                .font(.system(size: 18, weight: .heavy))
                        }).foregroundColor(Color(uiColor: .label))
                    }
                    .padding(.vertical, 20)
                    .padding(.horizontal, 20)
                }
            }
            .transition(.scale)
            Spacer(minLength: 40)
        }
    }
}

struct VotePromo: View {
    var body: some View {
        NavigationLink(destination: VoteView()) {
            GroupedView {
                Text("Pick your games")
            }
        }
        Spacer(minLength: 40)
    }
}


struct WidgetPromo_Previews: PreviewProvider {
    static var previews: some View {
        WidgetPromo()
        VotePromo()
    }
}
