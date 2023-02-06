//
//  TeamLogo.swift
//  HockeyPal
//
//  Created by Pål Forsberg on 2021-01-10.
//

import SwiftUI

struct TeamLogo: View {
    var code: String
    var size: CGFloat = 30.0

    var body: some View {
        URLImage(url: "https://palsserver.com/shl-server/logo/\(code.lowercased()).png?v=0.2.0")
            .frame(width: size, height: size, alignment: .center)
    }

}

struct PlayerImage: View {
    var player: Int
    var size: CGFloat = 30.0

    var body: some View {
        URLImage(
            url: "https://palsserver.com/shl-server/player/\(player).jpg?v=0.2.0",
            placeholder: Image(systemName: "person.fill"))
            .frame(width: size, height: size * 1.2, alignment: .center)
            .cornerRadius(size / 6)
            .scaledToFit()
            .clipped()
    }
}

struct TeamLogo_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            TeamLogo(code: "LHF", size: 110)
            TeamLogo(code: "TBD", size: 110)
            PlayerImage(player: 206, size: 110)
            PlayerImage(player: 666, size: 110)
        }
    }
}
