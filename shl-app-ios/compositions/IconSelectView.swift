//
//  IconSelectView.swift
//  shl-app-ios
//
//  Created by Pål on 2023-03-17.
//

import SwiftUI


struct AppIconImage: View {
    var code: String?
    var size = CGFloat(40)
    var body: some View {
        Image(uiImage: UIImage(named: code ?? "puck-icon")?.withSize(targetSize: CGSize(width: size, height: size)) ?? UIImage())
            .resizable()
            .frame(width: size, height: size, alignment: /*@START_MENU_TOKEN@*/.center/*@END_MENU_TOKEN@*/)
            .clipShape(RoundedRectangle(cornerRadius: 5))
    }
}

struct Icon {
    let name: String
    let code: String?
}

struct IconSelectView: View {
    static var icons = [Icon(name: "Puck", code: nil),
                        Icon(name: "Puck Is", code: "puck-icon-ice"),
                        Icon(name: "Puck Inverterad", code: "puck-icon-inverted"),
                        Icon(name: "Puck Natt", code: "puck-icon-night"),
                        Icon(name: "Puck Sträckad", code: "puck-line"),
                        Icon(name: "Puck GPT", code: "puck-real"),
                        Icon(name: "Brynäs", code: "bif-icon"),
                        Icon(name: "Frölunda", code: "fhc-icon"),
                        Icon(name: "Färjestad", code: "fbk-icon"),
                        Icon(name: "HV71", code: "hv71-icon"),
                        Icon(name: "Leksand", code: "lif-icon"),
                        Icon(name: "Linköping", code: "lhc-icon"),
                        Icon(name: "Luleå", code: "lhf-icon"),
                        Icon(name: "Malmö", code: "mif-icon"),
                        Icon(name: "MoDo", code: "modo-icon"),
                        Icon(name: "Rögle", code: "rbk-icon"),
                        Icon(name: "Skellefteå", code: "saik-icon"),
                        Icon(name: "Timrå", code: "tik-icon"),
                        Icon(name: "Växjö", code: "vlh-icon"),
                        Icon(name: "Örebro", code: "ohk-icon"),
                        
                        Icon(name: "AIK", code: "aik-icon"),
                        Icon(name: "Almtuna", code: "ais-icon"),
                        Icon(name: "Björklöven", code: "ifb-icon"),
                        Icon(name: "Djurgården", code: "dif-icon"),
                        Icon(name: "Kalmar", code: "khc-icon"),
                        Icon(name: "Karlskoga", code: "bik-icon"),
                        Icon(name: "Mora", code: "mik-icon"),
                        Icon(name: "Nybro", code: "nvif-icon"),
                        Icon(name: "Oskarshamn", code: "iko2-icon"),
                        Icon(name: "Södertälje", code: "ssk-icon"),
                        Icon(name: "Tingsryd", code: "taif-icon"),
                        Icon(name: "Vimmerby", code: "vh-icon"),
                        Icon(name: "Västerås", code: "vik-icon"),
                        Icon(name: "Östersund", code: "ohik-icon"),
    ]

    @Binding var currentIcon: String?
    
    var body: some View {
        List(IconSelectView.icons, id: \.code) { e in
            Button(action: { self.select(code: e.code) }) {
                HStack(spacing: 15) {
                    AppIconImage(code: e.code)
                    Text(e.name)
                    if currentIcon == e.code {
                        Spacer()
                        Image(systemName: "checkmark")
                    }
                }
            }
            .tag(e.code)
            .padding(EdgeInsets(top: 6, leading: 0, bottom: 6, trailing: 0))
            .font(.system(size: 18, weight: .semibold, design: .rounded))
            .accentColor(Color(uiColor: .label))
        }
    }
    
    func select(code: String?) {
        guard code != self.currentIcon else {
            return
        }
        
        UIApplication.shared.setAlternateIconName(code) { error in
            if error == nil {
                withAnimation {
                    self.currentIcon = code
                }
            }
            print(error?.localizedDescription ?? "[SETTINGS] Changed app icon successfully \(code ?? "default")")
        }
    }
}

struct IconSelectView_Previews: PreviewProvider {
    static var previews: some View {
        IconSelectView(currentIcon: .constant(nil))
    }
}
