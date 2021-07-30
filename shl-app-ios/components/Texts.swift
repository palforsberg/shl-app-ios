//
//  Texts.swift
//  shl-app-ios
//
//  Created by Pål on 2021-07-30.
//

import SwiftUI

extension Text {

    func listHeader() -> some View {
        return self
            .font(.system(size: 18, design: .rounded))
            .fontWeight(.semibold)
            .foregroundColor(Color(UIColor.secondaryLabel))
            .textCase(.uppercase)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.leading, 45)
    }
    
    func points() -> some View {
        return self
            .font(.system(size: 14, design: .rounded))
            .fontWeight(.medium)
            .frame(width: 30, height: 20)
            .multilineTextAlignment(.trailing)
    }
}
