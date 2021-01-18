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
    internal let progress: Progress
    internal private (set) var isRunning: Bool = true
    
    internal private(set) var failureHandler:
        ((StorageTaskSnapshotInterface) -> Void)?
    internal private(set) var pauseHandler:
        ((StorageTaskSnapshotInterface) -> Void)?
    internal private(set) var progressHandler:
        ((StorageTaskSnapshotInterface) -> Void)?
    internal private(set) var resumeHandler:
        ((StorageTaskSnapshotInterface) -> Void)?
    internal private(set) var successHandler:
        ((StorageTaskSnapshotInterface) -> Void)?
    
    // SHOULD BE WEAK?
    private var handler: ((StorageTaskSnapshotInterface) -> Void)? = nil
    
    init(){
        let progress = Progress(totalUnitCount: 1000)
        self.progress = progress
    }
    
    func sendError(error: Error){
        self.failureHandler?(
            DummyStorageTaskSnapshot(
                error: error,
                statusInterface: .failure,
                progress: nil
            )
        )
    }
    func sendPause(){
        self.pauseHandler?(
            DummyStorageTaskSnapshot(
                error: nil,
                statusInterface: StorageTaskStatusInterface.pause,
                progress: nil
            )
        )
    }
    func sendProgress(ratioComplete: Double){
        guard self.isRunning
        else { return }
        self.progress.completedUnitCount =
            Int64(Int(ratioComplete * Double(self.progress.totalUnitCount)))
        self.progressHandler?(
            DummyStorageTaskSnapshot(
                error: nil,
                statusInterface: StorageTaskStatusInterface.progress,
                progress: self.progress
            )
        )
    }
    func sendResume(){
        self.resumeHandler?(
            DummyStorageTaskSnapshot(
                error: nil,
                statusInterface: StorageTaskStatusInterface.resume,
                progress: nil
            )
        )
    }
    func sendSuccess(){
        self.successHandler?(
            DummyStorageTaskSnapshot(
                error: nil,
                statusInterface: StorageTaskStatusInterface.success,
                progress: nil
            )
        )
    }
    
    /// Not sure how Firebase handles it, but this class only manages one handler at a time. Adding a second observer will overwrite the first.
    func observeInterface(
        _ status: StorageTaskStatusInterface,
        handler: @escaping (StorageTaskSnapshotInterface) -> Void
    ) {
        switch status {
        case .failure: self.failureHandler = handler
        case .pause: self.pauseHandler = handler
        case .progress: self.progressHandler = handler
        case .resume: self.resumeHandler = handler
        case .success: self.successHandler = handler
        case .unknown: break
        }
    }
    
    func pause() {
        print("This does nothing.")
        self.isRunning = false
        self.sendPause()
    }
    
    func cancel() {
        self.isRunning = false
        // I'm not sure what happens when a cancel is sent. Error?
        self.sendError(error: NSError(domain: "User cancelled", code: 1))
        print("This does nothing.")
    }
    
    func resume() {
        self.isRunning = true
        self.sendResume()
    }
}




// MARK: - SIMPLE ERROR TASK
/// Sends 2 progress and then one error after 1.5 second
class DummyErrorDownloadTask: DummyStorageDownloadTask {
    override init(){
        super.init()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.sendProgress(ratioComplete: 0.2)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.sendProgress(ratioComplete: 0.4)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            self.sendError(error: NSError(domain: "asdf", code: 4))
        }
    }
}

class DummySuccessDownloadTask: DummyStorageDownloadTask {
    override init(){
        super.init()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.sendProgress(ratioComplete: 0.3)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.sendProgress(ratioComplete: 0.6)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            self.sendProgress(ratioComplete: 0.8)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            self.sendProgress(ratioComplete: 1.0)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            self.sendSuccess()
        }
    }
}
