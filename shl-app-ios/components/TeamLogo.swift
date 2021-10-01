//
//  TeamLogo.swift
//  HockeyPal
//
//  Created by Pål Forsberg on 2021-01-10.
//

import SwiftUI

enum LogoSize {
    case mini
    case small
    case medium
    case big
}
struct TeamLogo: View {
    var code: String
    var size = LogoSize.small

    var body: some View {
        URLImage(url: "https://palsserver.com/shl-server/logo/\(code.lowercased()).png")
                .frame(width: getSize(), height: getSize(), alignment: .center)
    }
    
    func getSize() -> CGFloat {
        switch size {
            case .mini: return 19
            case .small: return 30
            case .medium: return 25
            case .big: return 50
        }
    }
}

struct TeamLogo_Previews: PreviewProvider {
    static var previews: some View {
        TeamLogo(code: "LHF")
    }
}
