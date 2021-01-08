//
//  StandingsView.swift
//  HockeyPal
//
//  Created by Pål Forsberg on 2021-01-08.
//

import SwiftUI

struct StandingsView: View {
    var body: some View {
        NavigationView {
            List(/*@START_MENU_TOKEN@*/0 ..< 5/*@END_MENU_TOKEN@*/) { item in
                HStack() {
                    Text("#\(item + 1)")
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .foregroundColor(Color.gray)
                    Text("Luleå HC")
                        .font(.headline)
                        .fontWeight(.medium)
                    Spacer()
                    Text("23")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .multilineTextAlignment(.trailing)
                    Text("23")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    Text("23")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .padding(.trailing, 5.0)
                }
                .padding(.vertical, 5.0)
            }.navigationBarTitle(Text("SHL"))
            Color.gray
        }
    }
}

struct StandingsView_Previews: PreviewProvider {
    static var previews: some View {
        StandingsView()
    }
}
