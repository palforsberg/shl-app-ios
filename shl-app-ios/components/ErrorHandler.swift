//
//  ErrorHandler.swift
//  shl-app-ios
//
//  Created by Pål on 2023-07-09.
//

import Foundation


class ErrorHandler: ObservableObject {
    @Published var error: String?
    
    func set(error: String?) {
        self.error = error   
    }
}
