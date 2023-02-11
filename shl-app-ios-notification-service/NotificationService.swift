//
//  NotificationService.swift
//  shl-app-ios-notification-service
//
//  Created by Pål on 2023-02-06.
//
import UIKit
import UserNotifications
import AVFoundation

class NotificationService: UNNotificationServiceExtension {

    var contentHandler: ((UNNotificationContent) -> Void)?
    var bestAttemptContent: UNMutableNotificationContent?

    override func didReceive(_ request: UNNotificationRequest, withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void) {
        self.contentHandler = contentHandler
        bestAttemptContent = (request.content.mutableCopy() as? UNMutableNotificationContent)

        func failEarly() {
            contentHandler(request.content)
        }

        guard let content = (request.content.mutableCopy() as? UNMutableNotificationContent) else {
            return failEarly()
        }

        guard let attachments = content.userInfo["localAttachements"] as? [String] else {
            return failEarly()
        }

        guard let attachement = NotificationService.createAttachementImage(attachments) else {
            return failEarly()
        }
        
        content.attachments = [attachement]
        contentHandler(content.copy() as! UNNotificationContent)
    }
    
    override func serviceExtensionTimeWillExpire() {
        // Called just before the extension will be terminated by the system.
        // Use this as an opportunity to deliver your "best attempt" at modified content, otherwise the original push payload will be used.
        if let contentHandler = contentHandler, let bestAttemptContent =  bestAttemptContent {
            contentHandler(bestAttemptContent)
        }
    }
    
    static func createAttachementImage(_ attachements: [String]) -> UNNotificationAttachment? {
        guard attachements.count > 0,
              let frontImg = UIImage(named: "\(attachements[safe: 0]?.lowercased() ?? "")-big.png")
            else {
            return nil
        }
        let size = CGSize(width: 1024, height: 1024)
        UIGraphicsBeginImageContext(size)
        if let backImg = UIImage(named: "\(attachements[safe: 1]?.lowercased() ?? "")-big.png") {
            let frontSize: CGFloat = 820
            let backSize: CGFloat = 512
            backImg.draw(in: AVMakeRect(aspectRatio: backImg.size, insideRect: CGRect(x: size.width - backSize, y: 0, width: backSize, height: backSize)))
            frontImg.draw(in: AVMakeRect(aspectRatio: frontImg.size, insideRect: CGRect(x: 0, y: size.height - frontSize, width: frontSize, height: frontSize)))
        } else {
            let frontSize: CGFloat = size.height
            frontImg.draw(in: AVMakeRect(aspectRatio: frontImg.size, insideRect: CGRect(x: 0, y: 0, width: frontSize, height: frontSize)))
        }

        let newImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        
        return UNNotificationAttachment.create("img.png", data: newImage.pngData()!, options: nil)
    }
}

extension UNNotificationAttachment {

    /// Save the image to disk
    static func create(_ imageFileIdentifier: String, data: Data, options: [NSObject : AnyObject]?) -> UNNotificationAttachment? {
        let fileManager = FileManager.default
        let tmpSubFolderName = ProcessInfo.processInfo.globallyUniqueString
        let tmpSubFolderURL = NSURL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(tmpSubFolderName, isDirectory: true)

        do {
            try fileManager.createDirectory(at: tmpSubFolderURL!, withIntermediateDirectories: true)
            let fileURL = tmpSubFolderURL?.appendingPathComponent(imageFileIdentifier)
            try data.write(to: fileURL!, options: [])
            let imageAttachment = try UNNotificationAttachment.init(identifier: imageFileIdentifier, url: fileURL!, options: options)
            return imageAttachment
        } catch let error {
            print("error \(error)")
        }

        return nil
    }
}


extension Collection {
    /// Returns the element at the specified index if it is within bounds, otherwise nil.
    subscript (safe index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}
