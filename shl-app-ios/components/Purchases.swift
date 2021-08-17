//
//  Purchases.swift
//  shl-app-ios
//
//  Created by Pål on 2021-08-16.
//

import Foundation
import StoreKit

class Purchases : NSObject, ObservableObject {
    
    public static var shared: Purchases?
    private static let season21 = "season.2021"
    
    private let productIdentifiers: Set<String>
    private var purchasedProductIdentifiers: Set<String> = []
    private var productsRequest: SKProductsRequest?
    private var productsRequestCompletionHandler: ((Bool, [SKProduct]?) -> ())?
    private var purchaseCompletionHandler: ((String?) -> ())?
    private var settings: Settings
    
    
    init(settings: Settings) {
        self.settings = settings
        productIdentifiers = [Purchases.season21]
        
        for productIdentifier in productIdentifiers {
            let purchased = UserDefaults.standard.bool(forKey: productIdentifier)
            if purchased {
                purchasedProductIdentifiers.insert(productIdentifier)
                print("[BUY] Previously purchased: \(productIdentifier)")
            } else {
                print("[BUY] Not purchased: \(productIdentifier)")
            }
        }
        super.init()
        SKPaymentQueue.default().add(self)
    }
    
    public func canMakePayments() -> Bool {
        return SKPaymentQueue.canMakePayments()
    }
    
    public func restorePurchases(completionHandler: @escaping (String?) -> ()) {
        self.purchaseCompletionHandler = completionHandler
        SKPaymentQueue.default().restoreCompletedTransactions()
    }
    
    public func buyProduct(_ product: SKProduct, completionHandler: @escaping (String?) -> ()) {
        print("[BUY] Buying \(product.productIdentifier)...")
        let payment = SKPayment(product: product)
        SKPaymentQueue.default().add(payment)
        self.purchaseCompletionHandler = completionHandler
    }
    
    public func isProductPurchased(_ productId: String) -> Bool{
        return purchasedProductIdentifiers.contains(productId)
    }
    
    public func requestProducts(completionHandler: ((Bool, [SKProduct]?) -> ())?) {
        productsRequest?.cancel()
        productsRequestCompletionHandler = completionHandler
        productsRequest = SKProductsRequest(productIdentifiers: productIdentifiers)
        productsRequest!.delegate = self
        productsRequest!.start()
    }
}

extension Purchases: SKProductsRequestDelegate {
    public func productsRequest(_ request: SKProductsRequest, didReceive response: SKProductsResponse) {
        let products = response.products
        productsRequestCompletionHandler?(true, products)
        clearRequestAndHandler()
        
        for p in products {
            print("[BUY] Found product: \(p.productIdentifier) \(p.localizedTitle) \(p.price.floatValue)")
        }
    }
    
    public func request(_ request: SKRequest, didFailWithError error: Error) {
        print("[BUY] Failed to load list of products.")
        print("[BUY] Error: \(error.localizedDescription)")
        productsRequestCompletionHandler?(false, nil)
        clearRequestAndHandler()
    }
    
    private func clearRequestAndHandler() {
        productsRequest = nil
        productsRequestCompletionHandler = nil
        purchaseCompletionHandler = nil
    }
}

extension Purchases: SKPaymentTransactionObserver {
    
    public func paymentQueue(_ queue: SKPaymentQueue,
                             updatedTransactions transactions: [SKPaymentTransaction]) {
        for transaction in transactions {
            switch transaction.transactionState {
                case .purchased:
                    complete(transaction: transaction)
                    break
                case .failed:
                    fail(transaction: transaction)
                    break
                case .restored:
                    restore(transaction: transaction)
                    break
                case .deferred:
                    break
                case .purchasing:
                    break
                default:
                    break
            }
        }
    }
    
    public func paymentQueue(_ queue: SKPaymentQueue, restoreCompletedTransactionsFailedWithError error: Error) {
        purchaseCompletionHandler?(error.localizedDescription)
    }
    
    private func complete(transaction: SKPaymentTransaction) {
        print("[BUY] complete...")
        deliverPurchaseNotificationFor(identifier: transaction.payment.productIdentifier)
        SKPaymentQueue.default().finishTransaction(transaction)
    }
    
    private func restore(transaction: SKPaymentTransaction) {
        guard let productIdentifier = transaction.original?.payment.productIdentifier else { return }
        
        print("[BUY] restore...")
        deliverPurchaseNotificationFor(identifier: productIdentifier)
        SKPaymentQueue.default().finishTransaction(transaction)
    }
    
    private func fail(transaction: SKPaymentTransaction) {
        print("[BUY] fail...\(String(describing: transaction.error))")
        if let transactionError = transaction.error as NSError?,
           let localizedDescription = transaction.error?.localizedDescription,
           transactionError.code != SKError.paymentCancelled.rawValue {
            print("[BUY] Transaction Error: \(localizedDescription)")
            purchaseCompletionHandler?(localizedDescription)
        } else {
            purchaseCompletionHandler?("Failed")
        }
        
        
        SKPaymentQueue.default().finishTransaction(transaction)
    }
    
    private func deliverPurchaseNotificationFor(identifier: String?) {
        guard let identifier = identifier else { return }
        
        purchasedProductIdentifiers.insert(identifier)
        UserDefaults.standard.set(true, forKey: identifier)
        settings.supporter = true
        purchaseCompletionHandler?(nil)
    }
}

extension SKProduct {
    var localizedPrice: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = priceLocale
        return formatter.string(from: price)!
    }
}
