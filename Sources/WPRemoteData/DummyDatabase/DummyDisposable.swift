//
//  File.swift
//  
//
//  Created by William Piotrowski on 1/14/21.
//

import Foundation

/// Class meant to simulate a `Firestore` `ListenerRegistration`.
/// - note: Could possibly get this to function correctly if the class uses a Generic type and then requires the callback enclosure of the signal. Then this class stores that callback as a weak variable that is released when disposal (remove) is called.
///
/// Weak may not work since it requires a class.
class DummyDisposable/*<Callback: Any>*/: NSObject {
    internal private (set) var isComplete: Bool = false
//    internal private (set) weak var callback: ((Callback) -> Void)?
    private let removeCallback: (()->Void)?
    init(
//        callback: @escaping (Callback) -> Void,
        removeCallback: (()->Void)? = nil
    ){
        self.removeCallback = removeCallback
//        self.callback = callback
    }
}
extension DummyDisposable: ListenerRegistrationInterface {
    func remove() {
        print("COMPLETED REMOVAL!!")
        self.isComplete = true
        self.removeCallback?()
//        self.callback = nil
    }
}
