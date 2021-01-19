//
//  File.swift
//  
//
//  Created by William Piotrowski on 1/18/21.
//

import Foundation
import ReactiveSwift

protocol NewDownloadTaskProtocol {
    
//    var hardRefresh: Bool { get }
    
    /// presents the current state of the app. Signal is completed and will not change after error or completion. Interruptions will not be forwarded. Errors will not throw, but there will be an error state.
    var stateProperty: Property<NewDownloadTaskState> { get }
    
    /// A signal that shows progress of the entire download – including subtasks. Reports the percent complete as fraction completed of Progress.
    /// Will send a final progress value when complete followed by a completion event.
    /// Will send an error event on error.
    /// Strangely, interruptions do show up here.
    /// Interruptions will not bubble up and this signal is not affected by the stopping and starting of the signal producer on start. Which will interrupt on pause.
    var progressSignal: Signal<Double, Error> { get }
    
    var progress: Progress { get }
    
    // Move this inside protocol.
    var state: NewDownloadTaskState { get }
    
    func start() -> SignalProducer<Double, Error>
    func attemptPause()
    func attemptCancel()
    
    /// Are all files local.
    var isLocal: Bool { get }
}
extension NewDownloadTaskProtocol {
    
    public var isComplete: Bool {
        self.state.isComplete
    }
    
    public var percentComplete: Double {
        return progress.fractionCompleted
    }
}
