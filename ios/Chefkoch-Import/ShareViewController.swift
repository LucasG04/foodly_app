//
//  ShareViewController.swift
//  Chefkoch-Import
//
//  Source of RSIShareViewController: https://github.com/KasemJaffer/receive_sharing_intent/blob/master/ios/Classes/RSIShareViewController.swift
//

import receive_sharing_intent
import MobileCoreServices
import UniformTypeIdentifiers

class ShareViewController: RSIShareViewController {
    open override func isContentValid() -> Bool {
        if let text = contentText, !text.isEmpty {
            return text.contains("chefkoch.")
        }
        return true
    }
}
