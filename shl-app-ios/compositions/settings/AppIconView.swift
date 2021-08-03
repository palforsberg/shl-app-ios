//
//  AppIconView.swift
//  shl-app-ios
//
//  Created by Pål on 2021-07-31.
//

import SwiftUI

struct Icon {
    var name: String
    var code: String?
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
            Picker(selection: $currentIndex, label: Label("App Icon", systemImage: "app").accentColor(Color.green), content: {
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
            }).onChange(of: currentIndex) { value in
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

struct AppIconView_Previews: PreviewProvider {
    static var previews: some View {
        List {
            Section(header: Text("")) {
                AppIconView()
            }
        }
        .listStyle(InsetGroupedListStyle())
        .navigationBarTitle(Text("Settings"))
    }
}
