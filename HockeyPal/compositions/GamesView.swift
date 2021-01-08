//
//  GameView.swift
//  HockeyPal
//
//  Created by Pål Forsberg on 2021-01-08.
//

import SwiftUI

struct GamesView: View {
    var body: some View {
        NavigationView {
            List(/*@START_MENU_TOKEN@*/0 ..< 5/*@END_MENU_TOKEN@*/) { item in
                VStack(alignment: .leading) {
                    HStack() {
                        Image(systemName: "person.circle")
                        Text("LHC")
                        Text("-")
                        Image(systemName: "person.circle")
                        Text("FBK")
                        Spacer()
                        Text("5 - 0")
                            .fontWeight(.heavy)
                    }
                    .padding(.trailing)
            
                    Text("Live 3rd")
                        .padding(.top, 2.0)
                }
            }.navigationBarTitle(Text("Games"))
            Color.gray
        }
    }
}

struct GamesView_Previews: PreviewProvider {
    static var previews: some View {
        GamesView()
    }
}
