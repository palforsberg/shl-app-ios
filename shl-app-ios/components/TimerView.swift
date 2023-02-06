//
//  TimerView.swift
//  shl-app-ios
//
//  Created by Pål on 2021-08-01.
//

import SwiftUI

extension AnyTransition{
    public static func flipText() -> AnyTransition {
        .asymmetric(insertion: .offset(y: -15).combined(with: .opacity), removal: .offset(y: 15).combined(with: .opacity))
    }
}
struct TimeLabel : View {
    let time: Int?
    let label: String
    var body: some View {
        Text("\(time ?? 0)")
            .font(.system(size: 20, design: .rounded)).fontWeight(.bold)
            .monospacedDigit()
            .id("\(time ?? 0)\(label)")
            .transition(.flipText())
        Text(label).font(.system(size: 16, design: .rounded)).fontWeight(.medium)
            .padding(.trailing, 8).padding(.top, 3)
    }
}

struct TimerView : View {
    
    @State var nowDate: Date = Date()
    @State var timer: Timer?
    
    let referenceDate: Date
    
    var body: some View {
        HStack(spacing: 2) {
            let comps = Calendar.current.dateComponents(
                [.day, .hour, .minute, .second],
                from: nowDate, to: referenceDate)
            TimeLabel(time: comps.day, label: "D")
            TimeLabel(time: comps.hour, label: "H")
            TimeLabel(time: comps.minute, label: "M")
            TimeLabel(time: comps.second, label: "S")
        }
        .onAppear(perform: {
            startTimer()
        }).onDisappear {
            stopTimer()
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willResignActiveNotification)) { _ in
            stopTimer()
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
            startTimer()
        }
    }
    
    func startTimer() {
        guard self.timer == nil else {
            return
        }
        
        self.timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) {_ in
            withAnimation {
                self.nowDate = Date()
            }
            if (referenceDate < self.nowDate) {
                stopTimer()
            }
        }
    }
    
    func stopTimer() {
        guard timer != nil else {
            return
        }
        self.timer?.invalidate()
        self.timer = nil
    }
}

struct TimerView_Previews: PreviewProvider {
    static var previews: some View {
        TimerView(referenceDate: Date().addingTimeInterval(TimeInterval(10)))
    }
}
