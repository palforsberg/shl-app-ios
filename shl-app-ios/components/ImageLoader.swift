//
//  ImageLoader.swift
//  LoadingImages
//
//  Created by Mohammad Azam on 6/20/19.
//  Copyright © 2019 Mohammad Azam. All rights reserved.
//
import Foundation
import SwiftUI
import Combine

extension URLCache {
    static var imageCache = URLCache(memoryCapacity: 50_000_000, diskCapacity: 50_000_000)
}

class ImageLoader: ObservableObject {
    @Published public var downloadedImage: UIImage?
    
    public init() {
        
    }
    
    func load(url: String) {
        
        guard let imageURL = URL(string: url) else {
            print("ImageURL is not correct!")
            return
        }
        
        let request = URLRequest(url: imageURL, cachePolicy: .reloadIgnoringLocalCacheData)
        
        if let cached = URLCache.imageCache.cachedResponse(for: request) {
            self.downloadedImage = UIImage(data: cached.data)
            
            let timestamp = cached.userInfo?["date"] as? Date ?? Date.distantPast
            let age = Date().timeIntervalSince(timestamp)
            let expirationAge: TimeInterval = 60 * 60 * 24 * 3
            
            debugPrint("[IMAGELOADER] Cached for \(url) \(age) vs \(expirationAge)")
            if age > expirationAge {
                debugPrint("[IMAGELOADER] Expired cache for \(url)")
                URLCache.imageCache.removeCachedResponse(for: request)
            } else {
                return
            }
        }
        
        debugPrint("[IMAGELOADER] Download \(url)")
        URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data, let response = response, error == nil else {
                self.downloadedImage = nil
                return
            }
            URLCache.imageCache.storeCachedResponse(
                CachedURLResponse(response: response, data: data, userInfo: ["date": Date()], storagePolicy: .allowed),
                for: request
            )
            debugPrint("[IMAGELOADER] Cache \(url) \(URLCache.imageCache.currentDiskUsage)")
            DispatchQueue.main.async {
                self.downloadedImage = UIImage(data: data)
            }
        }.resume()
    }
}
