//
//  TeamLogo.swift
//  HockeyPal
//
//  Created by Pål Forsberg on 2021-01-10.
//

import SwiftUI

enum LogoSize {
    case small
    case medium
    case big
}
struct TeamLogo: View {
    var code: String
    var size = LogoSize.small

    var body: some View {
        URLImage(url: "http://86.107.103.138/shl-server/logo/\(code.lowercased()).png")
                .frame(width: getSize(), height: getSize(), alignment: .center)
    }
    
    func getSize() -> CGFloat {
        switch size {
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
