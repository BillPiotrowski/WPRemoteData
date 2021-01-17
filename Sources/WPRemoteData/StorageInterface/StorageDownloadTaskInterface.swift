//
//  File.swift
//  
//
//  Created by William Piotrowski on 1/17/21.
//

import Foundation



public protocol StorageDownloadTaskInterface {
    func pause()
    func cancel()
    func resume()
    func observeInterface(
        _ status: StorageTaskStatusInterface,
        handler: @escaping (StorageTaskSnapshotInterface) -> Void
    )
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





