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

class ImageLoader: ObservableObject {
    private static var cache = NSCache<NSString, UIImage>()
    
    @Published public var downloadedImage: UIImage?
    
    public init() {
        
    }
    
    func load(url: String) {
        
        guard let imageURL = URL(string: url) else {
            print("ImageURL is not correct!")
            return
        }
        
        // Check for a cached image.
        if let cachedImage = ImageLoader.cache.object(forKey: NSString(string: url)) {
            self.downloadedImage = cachedImage
            return
        }
        debugPrint("[IMAGELOADER] Download image \(url)")
        URLSession.shared.dataTask(with: imageURL) { data, response, error in
            guard let data = data, error == nil else {
                self.downloadedImage = nil
                return
            }
            DispatchQueue.main.async {
                self.downloadedImage = UIImage(data: data)
                if (self.downloadedImage != nil) {
                    ImageLoader.cache.setObject(self.downloadedImage!, forKey: NSString(string: url), cost: data.count)
                }
            }
        }.resume()
    }
}
