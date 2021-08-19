//
//  RotateButton.swift
//  shl-app-ios
//
//  Created by Pål on 2021-08-19.
//

import SwiftUI

struct RotateButton<Label: View>: View {
    let action: () -> ()
    let label: Label
    
    @State
    var nrTaps = 0
    
    var body: some View {
        Button(action: {
            self.nrTaps += 1
            self.action()
        }, label: {
            self.label.rotationEffect(.degrees(360.0 * Double(nrTaps))).animation(.easeInOut(duration: 0.5))
        })
    }
}

struct RotateButton_Previews: PreviewProvider {
    static var previews: some View {
        RotateButton(action: { print("triggered") }, label: Image(systemName: "arrow.clockwise.circle"))
    }
}
