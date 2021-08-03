//
//  SettingsView.swift
//  shl-app-ios
//
//  Created by Pål on 2021-07-31.
//

import SwiftUI

struct Icon {
    let name: String
    let code: String?
}

extension Label {
    func settingsItem() -> some View {
        return self
            .font(.system(size: 18, design: .rounded))
            .padding(.top, 10).padding(.bottom, 10)
    }
}
struct AppIconView: View {

    static var icons = [Icon(name: "Default", code: nil),
                 Icon(name: "Timrå IK", code: "tik")]

    @State var currentIndex: Int
    
    init() {
        self.currentIndex = AppIconView.getCurrentIndex()
    }
    
    var body: some View {
        Section {
            Picker(selection: $currentIndex, label: Label("App Icon", systemImage: "app")
                    .settingsItem()
                    .accentColor(Color.green)) {
                ForEach(0..<AppIconView.icons.count) { e in
                    HStack {
                        Image(uiImage: UIImage(named: AppIconView.icons[e].code ?? "default")!).resizable()
                            .frame(width: 30, height: 30, alignment: /*@START_MENU_TOKEN@*/.center/*@END_MENU_TOKEN@*/)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                        Text(AppIconView.icons[e].name)
                            .font(.system(size: 16, design: .rounded))
                            .fontWeight(.medium)
                            .padding(.leading, 5)
                    }.tag(e)
                }
            }.onChange(of: currentIndex) { value in
                if value != AppIconView.getCurrentIndex() {
                    UIApplication.shared.setAlternateIconName(AppIconView.icons[value].code){ error in
                        print(error?.localizedDescription ?? "Success")
                    }
                }
                
            }
        }
    }
    
    static func getCurrentIndex() -> Int {
        return self.icons.firstIndex { $0.code == UIApplication.shared.alternateIconName } ?? 0
    }
}

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
            Picker(selection: $currentIndex, label: Label("Season", systemImage: "calendar")
                    .settingsItem()
                    .accentColor(Color.red)) {
                ForEach(0..<SeasonPicker.seasons.count) { e in
                    HStack {
                        Text(Season.getFormatted(season: SeasonPicker.seasons[e]))
                            .font(.system(size: 16, design: .rounded))
                            .fontWeight(.medium)
                            .padding(.leading, 5)
                    }.tag(e)
                }
            }.onChange(of: currentIndex) { value in
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
                Label("Notifications", systemImage: "app.badge").settingsItem().accentColor(Color.blue)
                Label("Supporter", systemImage: "star").settingsItem().accentColor(Color.orange)
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
