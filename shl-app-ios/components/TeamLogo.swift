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
        if let teamImage = UIImage(named: self.getImageName()) {
            Image(uiImage: teamImage)
                .resizable()
                .scaledToFit()
                .frame(width: size, height: size, alignment: .center)
            
        } else {
            URLImage(
                url: "https://palsserver.com/shl-server/logo/\(code.lowercased()).png?v=\(Cache.getBuildVersionNumber() ?? "unknown")",
                placeholder: Image(systemName: "photo"))
            .frame(width: size, height: size, alignment: .center)
            .scaledToFit()
            .clipped()       
        }
    }
    
    func getImageName() -> String {
        if size > 128 {
            return "\(code.lowercased())-big.png"
        }
        return "\(code.lowercased()).png"
    }
}

struct TightTeamLogo: View {
    var code: String
    var size: CGFloat = 30.0

    var body: some View {
        if let teamImage = UIImage(named: self.getImageName()) {
            if teamImage.size.width < teamImage.size.height {
                Image(uiImage: teamImage)
                    .resizable()
                    .scaledToFit()
                    .frame(height: size, alignment: .center)
            } else {
                Image(uiImage: teamImage)
                    .resizable()
                    .scaledToFit()
                    .frame(width: size, alignment: .center)
            }
        } else {
            URLImage(
                url: "https://palsserver.com/shl-server/logo/\(code.lowercased()).png?v=\(Cache.getBuildVersionNumber() ?? "unknown")",
                placeholder: Image(systemName: "photo"))
            .frame(width: size, height: size, alignment: .center)
            .scaledToFit()
            .clipped()
        }
    }
    
    func getImageName() -> String {
        if size > 128 {
            return "\(code.lowercased())-big.png"
        }
        return "\(code.lowercased()).png"
    }
}

struct PlayerImage: View {
    var player: String
    var size: CGFloat = 30.0
    var cornerRadius: CGFloat?

    var body: some View {
        let url = "https://palsserver.com/shl-server/player/\(player).jpg"
        URLImage(url: url, placeholder: Image(systemName: "person.fill"))
            .frame(width: size, height: size * 1.2, alignment: .center)
            .cornerRadius(cornerRadius ?? size / 6)
            .scaledToFit()
            .clipped()
    }
}

struct TeamLogo_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            TeamLogo(code: "LHF", size: 110)
            TeamLogo(code: "MODO", size: 110)
            TeamLogo(code: "HV71", size: 110)
            TeamLogo(code: "TBD", size: 110)
            PlayerImage(player: "3524", size: 110)
            PlayerImage(player: "666", size: 110)
        }
    }
}
