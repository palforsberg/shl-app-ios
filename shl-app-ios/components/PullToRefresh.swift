//
//  PullToRefresh.swift
//  shl-app-ios
//
//  Created by Pål on 2022-07-21.
//

import SwiftUI

struct PullToRefresh: View {
    
    var coordinateSpaceName: String
    var onRefresh: ()->Void
    
    @State var needRefresh: Bool = false
    
    var body: some View {
        GeometryReader { geo in
            if (geo.frame(in: .named(coordinateSpaceName)).midY > 50) {
                Spacer()
                    .onAppear {
                        needRefresh = true
                    }
            } else if (geo.frame(in: .named(coordinateSpaceName)).maxY < 10) {
                Spacer()
                    .onAppear {
                        if needRefresh {
                            needRefresh = false
                            onRefresh()
                        }
                    }
            }
            HStack {
                Spacer()
                if needRefresh {
                    ProgressView().scaleEffect(1.5)
                }
                Spacer()
            }
        }.padding(.top, -50)
    }
}

struct PullToRefresh_Previews: PreviewProvider {
    static var previews: some View {
        PullToRefresh(coordinateSpaceName: "hejsan") {
            
        }
    }
}
