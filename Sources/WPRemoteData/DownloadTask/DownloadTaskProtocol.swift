//
//  File.swift
//  
//
//  Created by William Piotrowski on 1/18/21.
//

import Foundation
import ReactiveSwift

public protocol DownloadTaskProtocol: class {
    
//    var hardRefresh: Bool { get }
    
    /// The current state of the download task.
    ///
    /// Where possible, state will always be set prior to sending a progress property. So checking state after a progress update should always be `loading` or `complete` if subscribed to a `progressSignalProducer`. There is a change that a `progressSignal` could receive a proress event while paused if a task is completing that was initiated prior to pause.
    ///
    /// Signal is completed and will not change after error or completion. Interruptions will not be forwarded. Errors will not throw, but there will be an error state.
    var stateProperty: Property<NewDownloadTaskState> { get }
    
    /// A signal that shows progress of the entire download – including subtasks. Reports the percent complete as fraction completed of Progress.
    ///
    /// Should send a final progress value when complete followed by a completion event, but this is not currently enforced and depends on underlying task.
    ///
    /// - note: Design decition as to whether or not to force a 1.0 progress prior to completing as it may be a duplicate. Possibly put a skipRepeats() to mitigate?
    ///
    /// Signal is failable on error, but unlike the progressSignalProducer, this will NOT send interruptions.
    ///
    /// Should include unit tests to verify this.
    var progressSignal: Signal<Double, Error> { get }
    
    var progress: Progress { get }
    
    ///
    ///
    /// - note: By design, state immediately represents the use-initiated state of the task, but may not always be accurate to the underlying task.
    ///
    /// For example: If the use pauses a download task, the state is immediately set to .paused, and the request to pause is sent to the underlying task, but a task in progress may still complete depending on how it handles the pause request.
    ///
    /// In this example, if the in-progress task does complete after the pause method is called, when the task is restarted, it will immediately return a progress of 1.0 and completion.
    var state: NewDownloadTaskState { get }
    
    
    /// Returns a Signal Producer with the Double indicating percentage complete from 0.0 to 1.0
    ///
    /// If there file is local and hardRefresh is set to false, it will immediately return a completed event.
    ///
    /// An attempt to start after the download has already completed will return a SignalProducer with an immediate value event (should be 1.0 since complete) and then a completion event.
    ///
    /// - todo: Design and test what happens when start() is called while already in a .loading state.
    ///
    func start() -> SignalProducer<Double, Error>
    
    func attemptPause()
    
    func attemptCancel()
    
    /// Are all files local.
    var isLocal: Bool { get }
    
    /// Currently only has an affect at init or when a parent task is initialized. In future can change this so that there is a didSet { } method, but seems unneccessary right now.
    var hardRefresh: Bool { get set }
}
extension DownloadTaskProtocol {
    public static var defaultHardRefresh: Bool {
        false
    }
    public var isComplete: Bool { state.isComplete }
    public var isError: Bool { state.isError }
    public var isTerminated: Bool { state.isTerminated }
    
    public var percentComplete: Double {
        return progress.fractionCompleted
    }
}

// MARK: - PROGRESS SIGNAL PRODUCER
extension DownloadTaskProtocol {
    
    /// A SignalProducer representing the download task's progress.
    ///
    /// Will immediately return a value of the progress, followed by a stream of updates.
    ///
    /// Unlike the `progressSignal`, the SignalProducer will terminate on interruption (pause).
    ///
    /// Terminates on completion and fails on error.
    ///
    /// - note: This is the same `SignalProducer` that is returned when the `start()` method is called.
    ///
    public var progressSignalProducer: SignalProducer<Double, Error> {
        return SignalProducer<Double, Error>.init { (input, lifetime) in
            
            // !!! --- Order of events here is important. --- !!!
            
            // 0.5) Ensure hasn't already failed
            // Would prefer the state check below (2) to handle this, but for some reason, when task has already failed, it stops after sending the percentage value.
            // Hopeing this does not cause any latency in creation.
            guard !self.state.isError else {
                input.send(error: DownloadTaskError.alreadyFailed)
                return
            }
            
            // 1)
            input.send(value: self.percentComplete)
            
            // 2) Complete, if necessary.
            // Logically, would send the progress signal stream second to insure that all updates are caught,
            // But instead, checking for state so that a broken of completed stream is not sent (like would happen after task completion).
            
            let state = self.state
            switch state {
            case .complete: input.sendCompleted()
                // This should never fire because of guard above (0.5)
            case .failure(let error): input.send(error: error)
            case .paused: input.sendInterrupted()
            default: break
            }
            
            // 3) Observe stream in progress
            let progDisposable = self.progressSignal.observe(input)
            
            // 4) Observe manual interruption (pause) events.
            let stateDisposable = self.stateProperty.producer.startWithValues{
                switch $0 {
                case .paused: input.sendInterrupted()
                default: break
                }
            }
            
            lifetime.observeEnded {
                progDisposable?.dispose()
                stateDisposable.dispose()
            }
            
        }
    }
}







// MARK: - DEFINITIONS
// This will need to be renamed and removed from namespace if this becomes the model for all download tasks.
//extension NewDownloadTask {
    public enum NewDownloadTaskState: Equatable {
        public static func == (
            lhs: NewDownloadTaskState, rhs: NewDownloadTaskState
        ) -> Bool {
            switch (lhs, rhs) {
            case (.initialized, .initialized): return true
            case (.loading, .loading): return true
            case (.paused, .paused): return true
            case (.complete, .complete): return true
            case (.failure(let error1), .failure(let error2)):
                return error1.localizedDescription == error2.localizedDescription
            default: return false
            }
        }
        
        var isError: Bool {
            switch self {
            case .failure: return true
            default: return false
            }
        }
        var isComplete: Bool {
            switch self {
            case .complete: return true
            default: return false
            }
        }
        /// Returns true if isComplete or isError
        var isTerminated: Bool {
            return self.isError || self.isComplete
        }
        
        case initialized
        case loading
        case paused
        // Store localFile in completion
        case complete
        case failure(error: Error)
    }
//}
