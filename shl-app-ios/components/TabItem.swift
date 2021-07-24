//
//  TabItem.swift
//  HockeyPal
//
//  Created by Pål Forsberg on 2021-01-08.
//

import SwiftUI

struct TabItem: View {
    var text: String
    var image: String
    var body: some View {
        Text(text)
        Image(systemName: image)
    }
}

struct TabItem_Previews: PreviewProvider {
    static var previews: some View {
        TabItem(text: "Text", image: "phone.fill")
    }
}
