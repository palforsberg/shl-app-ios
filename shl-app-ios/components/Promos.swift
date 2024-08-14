//
//  Promos.swift
//  shl-app-ios
//
//  Created by Pål on 2023-05-27.
//

import SwiftUI



struct WidgetPromo: View {
    @AppStorage("icons.promo.2024.removed.2")
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
                    HStack(spacing: 10) {
                        Image(uiImage: UIImage(named: "NewIcons")!)
                            .antialiased(false)
                            .resizable()
                            .scaledToFit()
                            .rotation3DEffect(.degrees(10), axis: (x: 0.0, y: 1.0, z: 0.0))
                            .frame(width: 80)
                        VStack(alignment: .leading, spacing: 3) {
                            Text("PROMO.HEADER")
                                .font(.system(size: 18, weight: .heavy, design: .rounded))
                            Text("PROMO.BODY")
                                .font(.system(size: 14, weight: .heavy, design: .rounded))
                        }
                        Spacer()
                        Button(action: {
                            print("Remove Promo")
                            withAnimation {
                                removed = true
                            }
                        }, label: {
                            Image(systemName: "xmark")
                                .font(.system(size: 18, weight: .heavy))
                        }).foregroundColor(Color(uiColor: .label))
                    }
                    .padding(.vertical, 10)
                    .padding(.horizontal, 20)
                }
            }
            .transition(.scale)
            Spacer(minLength: 40)
        }
    }
}

struct WidgetPromo_Previews: PreviewProvider {
    static var previews: some View {
        WidgetPromo()
    }
}
