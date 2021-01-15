//
//  File.swift
//  
//
//  Created by William Piotrowski on 1/15/21.
//

import Foundation

// MARK: PROBABLY DELETE?
/// Disposable class intended to be used in the AddListener function.
///
/// Goal was to create a custom listener, so that it could `remove()` the Firestore `Listener` if the `Signal` was interrupted.
///
/// Assumed interruption would happen if signal was no longer retained, but could not simulate that situation (see tests).
///
/// Instead, just going to send the Firestore Listener instead of creating a custom one. In the future, might be worth exploring to ensure it is released if the signal is let go.
///
class ScorepioListenerDisposable: NSObject {
    internal private (set) var isDisposed: Bool = false
    private let removeCallback: (()->Void)?
    init(removeCallback: (()->Void)? = nil){
        self.removeCallback = removeCallback
    }
}
extension ScorepioListenerDisposable: ListenerRegistrationInterface {
    func remove() {
        self.isDisposed = true
        self.removeCallback?()
    }
}

