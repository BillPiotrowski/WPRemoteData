//
//  File.swift
//  
//
//  Created by William Piotrowski on 1/18/21.
//

import Foundation
import ReactiveSwift

public protocol NewDownloadTaskProtocol: class {
    
//    var hardRefresh: Bool { get }
    
    /// presents the current state of the app. Signal is completed and will not change after error or completion. Interruptions will not be forwarded. Errors will not throw, but there will be an error state.
    var stateProperty: Property<NewDownloadTaskState> { get }
    
    /// A signal that shows progress of the entire download – including subtasks. Reports the percent complete as fraction completed of Progress.
    /// Will send a final progress value when complete followed by a completion event.
    /// Will send an error event on error.
    /// Unlike the signal producer returned from the start() method, this signal will not pass interruptions.
    var progressSignal: Signal<Double, Error> { get }
    
    var progress: Progress { get }
    
    // Move this inside protocol.
    var state: NewDownloadTaskState { get }
    
    func start() -> SignalProducer<Double, Error>
    func attemptPause()
    func attemptCancel()
    
    /// Are all files local.
    var isLocal: Bool { get }
    
    /// Currently only has an affect at init or when a parent task is initialized. In future can change this so that there is a didSet { } method, but seems unneccessary right now.
    var hardRefresh: Bool { get set }
}
extension NewDownloadTaskProtocol {
    public static var defaultHardRefresh: Bool {
        false
    }
    public var isComplete: Bool {
        self.state.isComplete
    }
    
    public var percentComplete: Double {
        return progress.fractionCompleted
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
        
        case initialized
        case loading
        case paused
        // Store localFile in completion
        case complete
        case failure(error: Error)
    }
//}
