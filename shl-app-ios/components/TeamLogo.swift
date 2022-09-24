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
        URLImage(url: "https://palsserver.com/shl-server/logo/\(code.lowercased()).png?v=0.1.6")
                .frame(width: size, height: size, alignment: .center)
    }

}

struct TeamLogo_Previews: PreviewProvider {
    static var previews: some View {
        TeamLogo(code: "LHF")
    }
}
