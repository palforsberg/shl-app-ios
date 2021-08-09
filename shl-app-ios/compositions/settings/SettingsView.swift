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
                        Icon(name: "SHL", code: "shl-icon"),
                        Icon(name: "Timrå IK", code: "tik-icon"),
                        Icon(name: "Luleå HF", code: "lhf-icon"),
                        Icon(name: "HV71", code: "hv71-icon")]

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
                            .clipShape(RoundedRectangle(cornerRadius: 5))
                        Text(AppIconView.icons[e].name)
                            .font(.system(size: 16, design: .rounded))
                            .fontWeight(.medium)
                            .padding(.leading, 5)
                    }.tag(e)
                }
            }.onChange(of: currentIndex) { value in
                if value != AppIconView.getCurrentIndex() {
                    UIApplication.shared.setAlternateIconName(AppIconView.icons[value].code){ error in
                        print(error?.localizedDescription ?? "[SETTINGS] Changed app icon successfully")
                    }
                }
                
            }
        }
    }
    
    static func getCurrentIndex() -> Int {
        return self.icons.firstIndex { $0.code == UIApplication.shared.alternateIconName } ?? 0
    }
}

struct GeneralPicker<T: Equatable, Content: View>: View {

    var values: [T]
    
    @State var currentIndex: Int
    
    let onChange: (T) -> ()
    let content: (T) -> (Content)

    init(onChange: @escaping (T) -> (), values:[T], value: T, content: @escaping (T) -> (Content)) {
        self.onChange = onChange
        self.currentIndex = values.firstIndex(of: value)!
        self.values = values
        self.content = content
    }

    var body: some View {
        Section {
            Picker(selection: $currentIndex, label: Label("Season", systemImage: "calendar")
                    .settingsItem()
                    .accentColor(Color.red)) {
                ForEach(0..<self.values.count) { e in
                    HStack {
                        content(self.values[e])
                    }.tag(e)
                }
            }.onChange(of: currentIndex) { value in
                onChange(self.values[currentIndex])
            }
        }
    }
}

struct SeasonPicker: View {

    static var seasons = [2021, 2020, 2019, 2018, 2017]
    
    @Binding var currentSeason: Int

    var body: some View {
        GeneralPicker(onChange: { e in self.currentSeason = e }, values: SeasonPicker.seasons, value: currentSeason, content: {e in
            Text(Season.getFormatted(season: e))
                .font(.system(size: 16, design: .rounded))
                .fontWeight(.medium)
                .padding(.leading, 5)
        })
    }
}

struct FilterPicker: View {
    var filters = [true, false]
    
    @Binding var currentVal: Bool
    
    var body: some View {
        GeneralPicker(onChange: {e in self.currentVal = e}, values: filters, value: currentVal, content: {e in
            Text("\(e ? "Only Starred" : "All")")
                .font(.system(size: 16, design: .rounded))
                .fontWeight(.medium)
                .padding(.leading, 5)
        })
    }
}

struct SettingsView: View {
    @EnvironmentObject var season: Season
    @State var onlyStarred = true
    
    var body: some View {
        List {
            Section(header: Text("")) {
                SeasonPicker(currentSeason: $season.season)
                AppIconView()
                Label("Match Filter", systemImage: "loupe").settingsItem().accentColor(Color.purple)
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
