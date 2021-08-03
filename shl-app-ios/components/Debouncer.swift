//
//  Debouncer.swift
//  shl-app-ios
//
//  Created by Pål on 2021-08-02.
//

import Foundation
import Combine

var cancellable: [AnyCancellable] = []
struct Debouncer {
    let subject = PassthroughSubject<Int, Never>()
    init(_ action: @escaping () -> (), seconds: Double) {
        subject
            .debounce(for: .seconds(seconds), scheduler: RunLoop.main)
            .sink { index in
                action()
            }.store(in: &cancellable)
    }
    
    func send() {
        subject.send(1)
    }
}
