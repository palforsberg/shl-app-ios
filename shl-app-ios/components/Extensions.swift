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

        guard let descriptor = systemFont.fontDescriptor.withDesign(.rounded) else { return systemFont }
        return UIFont(descriptor: descriptor, size: size)
    }
}

extension Text {

    func listHeader(_ leading: Bool = false) -> some View {
        let txt = self
            .font(.system(size: 16, design: .rounded))
            .fontWeight(.bold)
            .foregroundColor(Color(.secondaryLabel))
            .textCase(.uppercase)
        if (leading) {
            return txt
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.leading, 15)
        }
        return txt
            .frame(maxWidth: .none)
            .padding(.leading, 0)
    }
    
    func starred(_ starred: Bool, height: CGFloat = 3) -> some View {
        return self.overlay(
            RoundedRectangle(cornerRadius: 2)
                .frame(height: height).frame(maxWidth: starred ? .infinity : 0).offset(y: 1)
                .foregroundColor(Color(UIColor.systemYellow).opacity(starred ? 1 : 0)), alignment: .bottom)
            .animation(.easeInOut(duration: 0.2), value: starred)
    }
}

extension UIScreen {
    static var isMini: Bool {
        get {
            UIScreen.main.bounds.size.width <= 380
        }
    }
}

extension UIImage {
    func withSize(targetSize: CGSize) -> UIImage {
        // Draw and return the resized UIImage
        let scaledImage = UIGraphicsImageRenderer(size: targetSize).image { _ in
            self.draw(in: CGRect(
                origin: .zero,
                size: targetSize
            ))
        }
        
        return scaledImage
    }
}


extension Date {
    func getFormattedDate() -> String {
        let dateformat = DateFormatter()
         
        dateformat.locale = Locale.current
         let dateDelta = Date.daysBetween(from: Date(), to: self)
     
         if (dateDelta < -1) {
             dateformat.dateFormat = "dd/MM"
         } else if (dateDelta < 1) {
             dateformat.doesRelativeDateFormatting = true
             dateformat.dateStyle = .short
         } else if (abs(dateDelta) < 7) {
             dateformat.dateFormat = "E"
         } else {
             dateformat.dateFormat = "dd/MM"
         }
        // return "\(Int.random(in: 0..<100))"
        return dateformat.string(from: self)
     }
    
    
    func getFormattedTime() -> String {
        let dateformat = DateFormatter()
        dateformat.locale = Locale.current
        dateformat.dateFormat = "HH:mm"
        return dateformat.string(from: self)
     }
    
    static func daysBetween(from: Date, to: Date) -> Int {
        return Calendar.current.dateComponents([.day], from: from, to: to).day!
    }
}

extension Collection {
    /// Returns the element at the specified index if it is within bounds, otherwise nil.
    subscript (safe index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}

extension UIColor {
    static var active = UIColor.systemGray4
}

struct ActiveButtonStyle: ButtonStyle {
    var activeBackground: Color = Color(UIColor.active)
    var background: Color = .clear
    func makeBody(configuration: Configuration) -> some View {
        return configuration.label
            .background(configuration.isPressed ? activeBackground : background)
    }
}

extension ForEach where Data.Element: Hashable, ID == Data.Element, Content: View {
    init(values: Data, content: @escaping (Data.Element) -> Content) {
        self.init(values, id: \.self, content: content)
    }
}

extension UserDefaults {
    static var shared: UserDefaults {
        return UserDefaults(suiteName: "group.palforsberg.shl-app-ios")!
    }
}

extension Data {
    func token() -> String {
        self.map { String(format: "%02.2hhx", $0) }.joined()
    }
}

extension Text {
    func rounded(size: CGFloat, weight: Font.Weight = .semibold) -> Text {
        self.font(.system(size: size, weight: weight, design: .rounded))
    }
}

public extension TimeInterval {

    /// `TimeInterval` representing *n* whole or fractional **days**.
    static func days(_ n: Double) -> TimeInterval {
        n * 86_400          // 24 × 3 600
    }

    /// `TimeInterval` representing *n* whole or fractional **hours**.
    static func hours(_ n: Double) -> TimeInterval {
        n * 3_600           // 60 × 60
    }

    /// `TimeInterval` representing *n* whole or fractional **minutes**.
    static func minutes(_ n: Double) -> TimeInterval {
        n * 60
    }

    /// (Optional) straight-through helper for seconds, for completeness.
    static func seconds(_ n: Double) -> TimeInterval {
        n
    }
}
