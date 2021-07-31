//
//  Texts.swift
//  shl-app-ios
//
//  Created by Pål on 2021-07-30.
//

import SwiftUI

extension UIFont {
    class func rounded(ofSize size: CGFloat, weight: UIFont.Weight) -> UIFont {
        let systemFont = UIFont.systemFont(ofSize: size, weight: weight)

        guard #available(iOS 13.0, *), let descriptor = systemFont.fontDescriptor.withDesign(.rounded) else { return systemFont }
        return UIFont(descriptor: descriptor, size: size)
    }
}

extension Text {

    func listHeader() -> some View {
        return self
            .font(.system(size: 18, design: .rounded))
            .fontWeight(.semibold)
            .foregroundColor(Color(UIColor.secondaryLabel))
            .textCase(.uppercase)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.leading, 25)
    }
    
    func points() -> some View {
        return self
            .font(.system(size: 14, design: .rounded))
            .fontWeight(.medium)
            .frame(width: 30, height: 20)
            .multilineTextAlignment(.trailing)
    }
}
