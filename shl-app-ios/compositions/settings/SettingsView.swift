//
//  SettingsView.swift
//  shl-app-ios
//
//  Created by Pål on 2021-07-31.
//

import SwiftUI

struct SeasonPicker: View {

    static var seasons = [2021, 2020, 2019, 2018, 2017]
    
    @State var currentIndex: Int
    
    let onChange: (Int) -> ()

    init(onChange: @escaping (Int) -> (), season: Int) {
        self.onChange = onChange
        self.currentIndex = SeasonPicker.seasons.firstIndex(of: season)!
    }

    var body: some View {
        Section {
            Picker(selection: $currentIndex, label: Label("Season", systemImage: "calendar").accentColor(Color.red), content: {
                ForEach(0..<SeasonPicker.seasons.count) { e in
                    HStack {
                        Text(Season.getFormatted(season: SeasonPicker.seasons[e]))
                            .font(.system(size: 16, design: .rounded))
                            .fontWeight(.medium)
                            .padding(.leading, 5)
                    }.tag(e)
                }
            }).onChange(of: currentIndex) { value in
                onChange(SeasonPicker.seasons[currentIndex])
            }
        }
    }
}

struct SettingsView: View {
    @EnvironmentObject var season: Season
    
    var body: some View {
        List {
            Section(header: Text("")) {
                SeasonPicker(onChange: { e in season.set(e) }, season: season.season)
                AppIconView()
                Label("Notifications", systemImage: "app.badge").accentColor(Color.blue)
                Label("Supporter", systemImage: "star").accentColor(Color.orange)
            }
        }
        .listStyle(InsetGroupedListStyle())
        .navigationBarTitle(Text("Settings"))
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
            .environmentObject(Season())
            .environment(\.locale, .init(identifier: "sv"))
    }
}
