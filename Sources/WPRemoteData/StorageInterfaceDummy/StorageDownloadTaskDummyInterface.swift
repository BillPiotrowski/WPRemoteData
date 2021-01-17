//
//  File.swift
//  
//
//  Created by William Piotrowski on 1/17/21.
//

import Foundation

/// Is a class in Firebase. Likely to maintain Progress?
///
/// https://firebase.google.com/docs/reference/swift/firebasestorage/api/reference/Classes/StorageTaskSnapshot
struct DummyStorageTaskSnapshot: StorageTaskSnapshotInterface {
    var error: Error?
    var statusInterface: StorageTaskStatusInterface
    var progress: Progress?
}



class DummyStorageDownloadTask: StorageDownloadTaskInterface {
    func observeInterface(
        _ status: StorageTaskStatusInterface,
        handler: @escaping (StorageTaskSnapshotInterface) -> Void
    ) {
        handler(
            DummyStorageTaskSnapshot(
                error: NSError(domain: "dummy error", code: 1),
                statusInterface: .failure,
                progress: Progress()
            )
        )
    }
    
    func pause() {
        print("This does nothing.")
    }
    
    func cancel() {
        print("This does nothing.")
    }
    
    func resume() {
        print("This does nothing.")
    }
}
