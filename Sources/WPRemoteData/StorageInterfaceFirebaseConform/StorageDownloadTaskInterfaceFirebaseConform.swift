//
//  File.swift
//  
//
//  Created by William Piotrowski on 1/17/21.
//

import Foundation
import FirebaseStorage


extension StorageTaskSnapshot: StorageTaskSnapshotInterface {
    public var statusInterface: StorageTaskStatusInterface {
        return self.status.storageTaskStatusInterface
    }
    
    
    
}


extension StorageDownloadTask: StorageDownloadTaskInterface {
    public func observeInterface(
        _ status: StorageTaskStatusInterface,
        handler: @escaping (StorageTaskSnapshotInterface) -> Void
    ) {
        self.observe(status.storageTaskStatus, handler: handler)
    }
    public func removeAllObserversInterface(
        for status: StorageTaskStatusInterface
    ){
        let state = status.storageTaskStatus
        self.removeAllObservers(for: state)
    }
}

fileprivate extension StorageTaskStatusInterface {
    var storageTaskStatus: StorageTaskStatus {
        switch  self {
        case .failure: return .failure
        case .pause: return .pause
        case .progress: return .progress
        case .resume: return .resume
        case .success: return .success
        case .unknown: return .unknown
        }
    }
}

extension StorageTaskStatus {
    var storageTaskStatusInterface: StorageTaskStatusInterface {
        switch self {
        case .failure: return .failure
        case .pause: return .pause
        case .progress: return .progress
        case .resume: return .resume
        case .success: return .success
        case .unknown: return .unknown
        @unknown default:
            // PRINT TO LOGS?
            return .unknown
        }
    }
}

