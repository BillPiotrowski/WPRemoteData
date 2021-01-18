//
//  File.swift
//  
//
//  Created by William Piotrowski on 1/17/21.
//

import Foundation



public protocol StorageDownloadTaskInterface {
    func pause()
    
    /// By looking at the Objective C code for Firebase, I think cancel will send an error when called.
    func cancel()
    func resume()
    
    /// Native Firebase version of this method returns a handle to remove the observer.
    ///
    /// Deciding this is not worth implementing, because observers should be all or nothing. No reason to add or remove specific ones.
    func observeInterface(
        _ status: StorageTaskStatusInterface,
        handler: @escaping (StorageTaskSnapshotInterface) -> Void
    )
    func removeAllObservers()
    func removeAllObserversInterface(for: StorageTaskStatusInterface)
}

public enum StorageTaskStatusInterface: Int {
    case unknown = 0
    case resume = 1
    case progress = 2
    case pause = 3
    case success = 4
    case failure = 5
}


public protocol StorageTaskSnapshotInterface {
    var error: Error? { get }
    var statusInterface: StorageTaskStatusInterface { get }
    var progress: Progress? { get }
}





