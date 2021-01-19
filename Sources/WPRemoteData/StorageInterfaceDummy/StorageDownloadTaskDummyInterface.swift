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



class DummyStorageDownloadTask {
    internal let progress: Progress
    
    /// When started or resumed, a random string is generated and set as a runningSessionID. This allows timers to check to make sure that it is the same start session that they were instantiated in before firing.
    fileprivate var runningSessionID: String? = nil
    var isRunning: Bool {
        runningSessionID != nil
    }
    
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
        
        self.runningSessionID = self.randomString()
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
    
}

// MARK: - CONFORM: StorageDownloadTaskInterface
extension DummyStorageDownloadTask: StorageDownloadTaskInterface {
    
    func pause() {
        self.runningSessionID = nil
        self.sendPause()
    }
    
    func cancel() {
        self.runningSessionID = nil
        // I'm not sure what happens when a cancel is sent. Error?
        // After looking at Firebase Objective C, I think an error is sent natively on cancel.
        self.sendError(
            error: NSError(domain: "User cancelled", code: 1)
        )
    }
    
    func resume() {
        self.runningSessionID = self.randomString()
        let sessionID = self.runningSessionID!
        self.sendResume()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            guard self.runningSessionID == sessionID else { return }
            self.sendProgress(ratioComplete: 0.8)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            guard self.runningSessionID == sessionID else { return }
            self.sendProgress(ratioComplete: 0.9)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            guard self.runningSessionID == sessionID else { return }
            self.sendProgress(ratioComplete: 1.0)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.1) {
            guard self.runningSessionID == sessionID else { return }
            self.sendSuccess()
        }
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
    
    func removeAllObservers(){
        self.removeAllObserversInterface(for: .failure)
        self.removeAllObserversInterface(for: .pause)
        self.removeAllObserversInterface(for: .progress)
        self.removeAllObserversInterface(for: .resume)
        self.removeAllObserversInterface(for: .success)
        self.handler = nil
    }
    
    func removeAllObserversInterface(
        for status: StorageTaskStatusInterface
    ){
        switch status {
        case .failure: self.failureHandler = nil
        case .pause: self.pauseHandler = nil
        case .progress: self.progressHandler = nil
        case .resume: self.resumeHandler = nil
        case .success: self.successHandler = nil
        case .unknown: break
        }
    }
    private func randomString() -> String {
//        func randomString(length: Int) -> String {
        let length = 11
          let letters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
          return String((0..<length).map{ _ in letters.randomElement()! })
//        }
    }
    
}




// MARK: - SIMPLE ERROR TASK
/// Sends 2 progress and then one error after 1.5 second
class DummyErrorDownloadTask: DummyStorageDownloadTask {
    override init(){
        super.init()
        let sessionID = self.runningSessionID!
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            guard self.runningSessionID == sessionID else { return }
            self.sendProgress(ratioComplete: 0.2)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            guard self.runningSessionID == sessionID else { return }
            self.sendProgress(ratioComplete: 0.4)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            guard self.runningSessionID == sessionID else { return }
            self.sendError(error: NSError(domain: "asdf", code: 4))
        }
    }
}

class DummySuccessDownloadTask: DummyStorageDownloadTask {
    override init(){
        super.init()
        let sessionID = self.runningSessionID!
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            guard self.runningSessionID == sessionID else { return }
            self.sendProgress(ratioComplete: 0.3)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            guard self.runningSessionID == sessionID else { return }
            self.sendProgress(ratioComplete: 0.6)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            guard self.runningSessionID == sessionID else { return }
            self.sendProgress(ratioComplete: 0.8)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            guard self.runningSessionID == sessionID else { return }
            self.sendProgress(ratioComplete: 1.0)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.1) {
            guard self.runningSessionID == sessionID else { return }
            self.sendSuccess()
        }
    }
}
class DummyQuickSuccessDownloadTask: DummyStorageDownloadTask {
    override init(){
        super.init()
        let sessionID = self.runningSessionID!
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
            guard self.runningSessionID == sessionID else { return }
            self.sendProgress(ratioComplete: 0.45)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.3) {
            guard self.runningSessionID == sessionID else { return }
            self.sendProgress(ratioComplete: 1.0)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.4) {
            guard self.runningSessionID == sessionID else { return }
            self.sendSuccess()
        }
    }
}
