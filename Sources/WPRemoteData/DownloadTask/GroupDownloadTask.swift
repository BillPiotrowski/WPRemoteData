//
//  File.swift
//  
//
//  Created by William Piotrowski on 1/18/21.
//

import Foundation
import ReactiveSwift

public class GroupDownloadTask {
    private let subtasks: [DownloadTaskProtocol]
    
    public let stateProperty: Property<NewDownloadTaskState>
    private let stateInput: Signal<NewDownloadTaskState, Never>.Observer
    public let progressSignal: Signal<Double, Error>
    private let progressInput: Signal<Double, Error>.Observer
    
    private let lifecycleDisposable = CompositeDisposable()
    public let progress: Progress
    public var hardRefresh: Bool
    
    let downloadOrder: DownloadOrder
    static let downloadOrderDefault = DownloadOrder.sequential
    
//
//    var interruptableInput: (Signal<Double, Error>.Observer)?
    
    public init(
        downloadTasks: [DownloadTaskProtocol],
        hardRefresh: Bool? = nil,
        downloadOrder: DownloadOrder? = nil
    ){
        
        let downloadOrder = downloadOrder ?? Self.downloadOrderDefault
        let progress: Progress = Progress()
        progress.fileOperationKind = .downloading
        // Sets progress totalUnitCount to 100 per subtask.
        // Sets totalUnitCount to 1 if there are no subtasks.
        // If this catch was not there, the total progress would be zero, which will not calculate correctly when start() is called.
        progress.totalUnitCount = (downloadTasks.count > 0) ?  Int64(downloadTasks.count * 100) : 1
        
        let initialState = NewDownloadTaskState.initialized
        
        // Creating a pipe to send the subtasks through which
        // This gives access to a way to manually fail or complete the progressSignal from the state changes.
        let signalPipe = Signal<Double, Error>.pipe()
        
        // Createa pipe to merge the subtask signals.
        let subtaskStatePipe = Signal<Signal<Double, Error>, Error>.pipe()
        
        // Flatten and merge the subtask signals and map to master Progress.
        let subtaskStateSignal = subtaskStatePipe.output
            .flatten(.merge).map { _ -> Double in
            progress.fractionCompleted
        }
        
        // Send subtask signals into the master signal pipe.
        // If there are 0 subtasks, the signal would automatically complete during init. Adding guard here so that the autocomplete will happen when started.
        if downloadTasks.count > 0 {
            subtaskStateSignal.observe(signalPipe.input)
        }
        
        // Send all subtask signals into subtask pipe and complete it.
        for task in downloadTasks {
            subtaskStatePipe.input.send(value: task.progressSignal)
        }
        subtaskStatePipe.input.sendCompleted()
        
        let statePipe = Signal<NewDownloadTaskState, Never>.pipe()
        let stateProperty = Property(
            initial: initialState,
            then: statePipe.output
        )
        
        for task in downloadTasks {
            progress.addChild(
                task.progress,
                withPendingUnitCount: 100
            )
            if let hardRefresh = hardRefresh {
                task.hardRefresh = hardRefresh
            }
        }
        let hardRefresh = hardRefresh ?? GroupDownloadTask.defaultHardRefresh
        
        
        self.progress = progress
        self.hardRefresh = hardRefresh
        self.stateProperty = stateProperty
        self.stateInput = statePipe.input
        self.subtasks = downloadTasks
        self.progressSignal = signalPipe.output
        self.downloadOrder = downloadOrder
        self.progressInput = signalPipe.input
        
        progressSignal.producer.startWithCompleted {
            self.state = .complete
        }
        progressSignal.producer.startWithFailed {
            self.state = .failure(error: $0)
        }
//        self.stateProperty.producer.startWithCompleted {
//            self.lifecycleDisposable.dispose()
//        }
        
        
        
    }
}
 
// MARK: - START
extension GroupDownloadTask: DownloadTaskProtocol {
    
    public func start() -> SignalProducer<Double, Error> {
        guard !self.isTerminated else {
            return self.progressSignalProducer
        }
        guard hardRefresh || !isLocal else {
            progress.completedUnitCount = progress.totalUnitCount
            self.state = .complete
            return self.progressSignalProducer
        }
        
        // ADD A GUARD TO ENSURE THAT IT IS NOT ALREADY LOADING!
        
        self.state = .loading
        
        switch downloadOrder {
        case .parallel:
            self.startParallel()
        case .sequential:
            try? self.startNextTask()
        }
        
        return self.progressSignalProducer
        
    }
}

// MARK: - PARALLEL
extension GroupDownloadTask {
    
    /// Begins all subtasks
    private func startParallel() {
        for task in subtasks {
            let _ = task.start()
        }
    }
}
 
// MARK: - SEQUENTIAL
extension GroupDownloadTask {
    
    /// Escaping recursive function that starts the next task and when it completes calls itself to begin the next task.
    private func startNextTask() throws {
        guard let nextTask = nextTask
        else {
            throw NSError(domain: "no next task", code: 2)
        }
        let disposable = nextTask.start().startWithCompleted {
            try? self.startNextTask()
        }
        self.lifecycleDisposable.add(disposable)
    }
    
    /// Returns the first task that is not complete.
    private var nextTask: DownloadTaskProtocol? {
        subtasks.first { !$0.isComplete }
    }
    
}

// MARK: - COMPUTED VARS
extension GroupDownloadTask {
    
    public var isLocal: Bool {
        for task in subtasks {
            guard task.isLocal
            else { return false }
        }
        return true
    }
    
    private var areSubtasksComplete: Bool {
        for task in subtasks {
            guard task.isComplete
            else { return false }
        }
        return true
    }
    
    public func attemptPause() {
        self.state = .paused
        for task in subtasks {
            task.attemptPause()
        }
    }
    
    
    public func attemptCancel() {
        self.state = .failure(error: DownloadTaskError.userCancelled)
        for task in subtasks {
            task.attemptCancel()
        }
    }
    
    public private (set) var state: NewDownloadTaskState {
        get { self.stateProperty.value }
        set {
            self.stateInput.send(value: newValue)
            switch newValue {
            case .complete:
                self.stateInput.sendCompleted()
                progressInput.sendCompleted()
            case .failure(let error):
                self.stateInput.sendCompleted()
                progressInput.send(error: error)
            case .initialized: break
            case .loading: break
            case .paused: break
            }
        }
    }
    
    
    public enum DownloadOrder {
        case parallel, sequential
    }
}
