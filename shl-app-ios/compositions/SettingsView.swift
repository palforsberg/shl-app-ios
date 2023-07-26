//
//  SettingsView.swift
//  shl-app-ios
//
//  Created by Pål on 2021-07-31.
//

import SwiftUI
import StoreKit

struct IconLabel: View {
    var text: String
    var color: Color
    var systemName: String
    
    var body: some View {
        StateView {
            HStack(spacing: 10) {
                Image(systemName: systemName)
                    .foregroundColor(color)
                Text(LocalizedStringKey(text))
                    .rounded(size: 16, weight: .semibold)
                    .padding(.vertical, 9)
            }
        }
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
        Picker(selection: $currentIndex, label: IconLabel(text: "Season", color: .red, systemName: "calendar")) {
                    ForEach(0..<self.values.count, id: \.self) { e in
                        HStack {
                            content(self.values[e])
                        }.tag(e)
                    }
        }.onChange(of: currentIndex) { value in
            onChange(self.values[currentIndex])
        }
    }
}

struct SeasonPicker: View {

    static var seasons = [2023, 2022, 2021, 2020, 2019, 2018]
    
    @Binding var currentSeason: Int

    var body: some View {
        GeneralPicker(onChange: { e in self.currentSeason = e }, values: SeasonPicker.seasons, value: currentSeason, content: {e in
            Text(Settings.getFormatted(season: e))
                .font(.system(size: 16, design: .rounded))
                .fontWeight(.medium)
                .padding(.leading, 5)
        })
    }
}


struct StateView<Content: View>: View {
    @Environment(\.isEnabled) var isEnabled
    
    var content: () -> Content
    var body: some View {
        content().opacity(isEnabled ? 1.0 : 0.5)
    }
}

struct RoundedRectangleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        MyButton(configuration: configuration)
    }
    
    struct MyButton: View {
        let configuration: ButtonStyle.Configuration
        @Environment(\.isEnabled)
        private var isEnabled: Bool
        
        var body: some View {
            HStack {
              Spacer()
              configuration.label.foregroundColor(.black)
              Spacer()
            }
            .padding()
            .scaleEffect(configuration.isPressed ? 0.95 : 1)
            .background(Color.yellow.cornerRadius(50))
            .opacity(isEnabled ? 1.0 : 0.5)
        }
    }
}

struct Puck: View {
    @Environment(\.colorScheme) var colorScheme
    
    var geo: GeometryProxy
    var scale = CGFloat(0.1)
    
    var body: some View {
        Image(uiImage: UIImage(named: colorScheme == .light ? "launch-puck-2" : "launch-puck-light-2") ?? UIImage())
            .resizable()
            .scaleEffect(scale)
            .scaledToFit()
    }
    
    func pos(_ x: CGFloat, _ y: CGFloat) -> some View {
        return self.position(x: x * geo.size.width, y: y * geo.size.height)
    }
}
struct SupporterView: View {
    
    @EnvironmentObject
    var settings: Settings
    
    @State
    var product: SKProduct?
    
    @State
    var hasLoadedProduct = true
    
    @State
    var purchasing = false
    
    @State
    var restoring = false
    
    @State
    var showAlert = false
    
    @State
    var errorMsg: String? = nil
    
    var body: some View {
        let canMakePayments = Purchases.shared?.canMakePayments() ?? false
        ZStack {
            Group {
                GeometryReader { geo in
                    Puck(geo: geo).pos(0.25, 0.11).animation(.easeOut(duration: 0.2))
                    Puck(geo: geo).pos(0.65, 0.08).animation(.easeOut(duration: 0.3))
                    Puck(geo: geo).pos(0.2, 0.64).animation(.easeOut(duration: 0.4))
                    Puck(geo: geo).pos(0.7, 0.6).animation(.easeOut(duration: 0.5))
                    Puck(geo: geo).pos(0.75, 0.85).animation(.easeOut(duration: 0.6))
                }
            }
            VStack(alignment: /*@START_MENU_TOKEN@*/.center/*@END_MENU_TOKEN@*/, spacing: 0) {
                HStack {
                    Image(systemName: "heart.fill")
                        .font(.system(size: 30, weight: .bold, design: .rounded))
                        .foregroundColor(.pink)
                    Text("Supporter")
                        .font(.system(size: 40, weight: .bold, design: .rounded))
                        .accentColor(Color.orange)
                }.padding(.top, 100).padding(.bottom, 5)
                
                HStack {
                    if settings.supporter {
                        Text("Unlocked Premium").font(.headline).multilineTextAlignment(.center)
                    } else {
                        Text("Unlock Premium \(product?.localizedPrice ?? "")")
                            .font(.headline)
                            .multilineTextAlignment(.center)
                    }
                }
                .padding()
                .frame(maxWidth: 300)
                VStack {
                    Group {
                        Text("App Icons")
                        Text("More Seasons")
                        Text("Match filter")
                    }
                    .font(.system(size: 17, weight: .semibold, design: .rounded)).foregroundColor(.secondary)
                    .padding(EdgeInsets(top: 2, leading: 00, bottom: 2, trailing: 0))
                }
                Spacer()
                if !settings.supporter {
                    Button(action: self.purchase, label: {
                        if purchasing {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: Color.black))
                        } else {
                            Text("Support").font(.system(size: 15, weight: .medium, design: .rounded))
                        }
                    })
                    .disabled(product == nil || purchasing || !canMakePayments)
                    .frame(maxWidth: 150)
                    .buttonStyle(RoundedRectangleButtonStyle())
                } else {
                    Text("Thanks").font(.headline)
                }
 
                Spacer()

            }.padding()
        }
        .navigationBarTitle("", displayMode: .inline)
        .navigationBarItems(trailing: Button(action: self.restore, label: {
            if restoring {
                ProgressView()
            } else {
                Text("Restore Purchase")
            }
        }))
        .alert(isPresented: $showAlert) { Alert(title: Text(errorMsg ?? "Purchase Restored")) }
        .onAppear { loadProducts() }
    }
    
    func loadProducts() {
        Purchases.shared?.requestProducts { success, products in
            self.hasLoadedProduct = true
            guard success, let product = products?.first else {
                print("[SUPPORTER] could not retrieve product")
                return
            }
            self.product = product
        }
    }
    
    func restore() {
        self.restoring = true
        Purchases.shared?.restorePurchases { error in
            self.errorMsg = error
            self.restoring = false
            self.showAlert = true
        }
    }

    func purchase() {
        guard let p = product else {
            return
        }
        self.purchasing = true
        Purchases.shared?.buyProduct(p) { error in
            self.errorMsg = error
            self.showAlert = errorMsg != nil
            self.purchasing = false
        }
    }
}

struct SettingsView: View {
    @EnvironmentObject var settings: Settings
    
    @State var currentIcon: String?
    
    var body: some View {
        List {
            Section(header: Text(""), footer: Text("TEAM_BODY").padding(.leading, 0).padding(.trailing, 20).padding(.top, 0)) {
                NavigationLink {
                    StarredTeamSelectView().navigationTitle("Your Teams")
                } label: {
                    IconLabel(text: "Your Teams", color: .yellow, systemName: "star")
                }
            }
            Section(header: Text(""), footer: Text("NOTIF_BODY").padding(.leading, 0).padding(.trailing, 20).padding(.top, 0)) {
                Toggle(isOn: $settings.notificationsEnabled, label: {
                    IconLabel(text: "Notifications", color: .blue, systemName: "app.badge")
                }).onChange(of: settings.notificationsEnabled) { enabled in
                    if enabled {
                        AppDelegate.registerForPushNotifications()
                    }
                }
            }
            Section(header: Text(""), footer: Text("SUPPORTER_BODY")
                .padding(.leading, 0).padding(.trailing, 20).padding(.top, 0)) {
                    NavigationLink {
                        SupporterView()
                    } label: {
                        IconLabel(text: "Supporter", color: .pink, systemName: settings.supporter ? "heart.fill" : "heart")
                    }
                Group {
                    NavigationLink {
                        IconSelectView(currentIcon: $currentIcon)
                    } label: {
                        HStack {
                            IconLabel(text: "App Icon", color: .green, systemName: "app")
                            Spacer()
                            AppIconImage(code: currentIcon, size: 30)
                        }
                    }
                    SeasonPicker(currentSeason: $settings.season)
                    HStack {
                        IconLabel(text: "Game Filter", color: .purple, systemName: "loupe")
                        Spacer()
                        Picker("", selection: $settings.onlyStarred) {
                            Text("⭐️").tag(true)
                            Text("All").tag(false)
                        }
                        .pickerStyle(SegmentedPickerStyle())
                        .frame(maxWidth: 130)
                    }
                    
                }
                #if DEBUG
                .disabled(false)
                #else
                .disabled(!settings.supporter)
                #endif
            }
            HStack {
                Spacer()
                VStack(alignment: .center) {
                    Text("Version \(Cache.getBuildVersionNumber() ?? "0.0")")
                    Text("User ID \(String(settings.uuid.prefix(4)))...\(String(settings.uuid.suffix(4)))")
                }
                Spacer()
            }
            .onTapGesture {
                UIPasteboard.general.string = """
                Version \(Cache.getBuildVersionNumber() ?? "0.0")
                User ID \(settings.uuid)
                """
            }
            .font(.system(size: 12, weight: .bold, design: .rounded))
            .foregroundColor(Color(uiColor: .tertiaryLabel))
            .listRowBackground(Color.clear)
        }
        .task {
            self.currentIcon = UIApplication.shared.alternateIconName
        }
        .listStyle(InsetGroupedListStyle())
        .navigationBarTitle(Text("Settings"))
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
            .environmentObject(Settings())
            .environment(\.locale, .init(identifier: "sv"))
    }
}


struct SupporterView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            SupporterView()
                .environmentObject(Settings())
                .environment(\.locale, .init(identifier: "sv"))
        }
    }
}
