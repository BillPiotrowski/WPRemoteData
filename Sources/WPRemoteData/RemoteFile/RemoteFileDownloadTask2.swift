//
//  File.swift
//  
//
//  Created by William Piotrowski on 1/17/21.
//

import Foundation
import SPCommon
import ReactiveSwift

class NewDownloadTask {
//    private let action: Action<Void, Double, Error>
    private let remoteFile: RemoteFileProtocol
    private let hardRefresh: Bool
    
    public let stateProperty: Property<State>
    private let stateInput: Signal<State, Never>.Observer
    
    // Not sure if second should be Error or Never
    private var progressSignalsInput: Signal<Signal<Double, Error>, Error>.Observer
    
    private var childProgress: Progress? {
        didSet {
            guard let childProgress = childProgress
            else { return }
            self.progress.addChild(
                childProgress,
                withPendingUnitCount: 1
            )
            
        }
    }
    
    public private (set) var progress: Progress
    
    // Should be weak in prod?
    internal var storageDownloadTask: StorageDownloadTaskInterface? = nil
    
    private let lifecycleDisposable = CompositeDisposable()
    
    init(
        remoteFile: RemoteFileProtocol,
        hardRefresh: Bool
    ){
        let progress: Progress = Progress()
        progress.fileOperationKind = .downloading
        progress.totalUnitCount = 1
        
        let initialState = State.initialized
        
        let statePipe = Signal<State, Never>.pipe()
        let stateProperty = Property(
            initial: initialState,
            then: statePipe.output
        )
        
        let progressSignalsPipe = Signal<Signal<Double, Error>, Error>.pipe()
        let flattenedSignal = progressSignalsPipe.output.flatten(.latest)
        
        let disposable1 = flattenedSignal.observe(
            Signal<Signal<Double, Error>.Value, Error>.Observer(
                value: { val in
                    statePipe.input.send(value: .loading)
                }, failed: { error in
                    statePipe.input.send(value: .failure(error: error))
                }, completed: {
                    statePipe.input.send(value: .complete)
                    statePipe.input.sendCompleted()
                }, interrupted: {
                    // Does not bubble up to outter from inner signals.
                }
            )
        )
        
        self.progressSignalsInput = progressSignalsPipe.input
        self.progress = progress
        self.hardRefresh = hardRefresh
        self.remoteFile = remoteFile
        self.stateProperty = stateProperty
        self.stateInput = statePipe.input
        
        // MARK: - INIT COMPLETE
        
        let disposable2 = self.stateProperty.producer.startWithValues {
            switch $0 {
            case .paused:
                // REMOVING ALL OBSERVERS WILL CAUSE HANLDER TO NOT BE CALLED. NOT USING YET, SO NOT A BIG DEAL.
                self.storageDownloadTask?.removeAllObservers()
                break
                
            case .complete:
                // These are not required, but cleaning up.
                self.storageDownloadTask?.removeAllObservers()
                self.lifecycleDisposable.dispose()
                self.storageDownloadTask = nil
                break
                
            case .failure:
                // These are not required, but cleaning up.
                self.storageDownloadTask?.removeAllObservers()
                self.storageDownloadTask = nil
                
                // !!! REQUIRED: !!!
                self.lifecycleDisposable.dispose()
                break
                
            case .loading, .initialized: break
            }
        }
        
        self.lifecycleDisposable.add(disposable1)
        self.lifecycleDisposable.add(disposable2)
        
    }
    
}

// MARK: - PUBLIC METHODS
extension NewDownloadTask {
    
    // Start creates a new signal and returns it / or producer.
    // when state changes the state new value setter checks for pause -> interrupts. and completions and errors.
    
    /// Returns a Signal Producer with the Double indicating percentage complete from 0.0 to 1.0
    ///
    /// If there file is local and hardRefresh is set to false, it will immediately return a completed event.
    ///
    /// An attempt to start after the download has already completed will return a SignalProducer with an immediate value event (should be 1.0 since complete) and then a completion event.
    func start() -> SignalProducer<Double, Error> {
        guard !self.isComplete
        else {
            return SignalProducer<Double, Error>.init(
                value: self.percentComplete
            )
        }
        guard hardRefresh || !localFile.exists
        else {
            progress.completedUnitCount = progress.totalUnitCount
            self.progressSignalsInput.sendCompleted()
            return SignalProducer<Double, Error>.init(
                value: self.percentComplete
            )
        }
        
        guard let downloadTask = self.storageDownloadTask
        else {
            return self.createNew()
        }
        return self.resumePrevious(downloadTask: downloadTask)
    }
    
    
    func cancel(){
        self.storageDownloadTask?.cancel()
    }
    func pause(){
        self.storageDownloadTask?.pause()
    }
}



// MARK: - CREATE / RESUME HELPERS
extension NewDownloadTask {
    
    /// If storageDownloadTaskInterface has already been set, a new one should not be created.
    ///
    /// That would create duplicate progress instances and leave the previous download task unresolved.
    private func resumePrevious(
        downloadTask: StorageDownloadTaskInterface
    ) -> SignalProducer<Double, Error> {
        let progressSignal = Signal<Double, Error>.pipe()
        
        setObservations(
            downloadTask: downloadTask,
            progressSignalInput: progressSignal.input
        )
        
        self.progressSignalsInput.send(value: progressSignal.output)
        
        downloadTask.resume()
        return progressSignal.output.producer
    }
    
    private func createNew() -> SignalProducer<Double, Error> {
        let progressSignal = Signal<Double, Error>.pipe()
        
        let downloadTask = remoteFile.ref.writeInterface(
            toFile: localFile.url,
            completion: self.downloadTaskComplete
        )
        self.storageDownloadTask = downloadTask
        
        setObservations(
            downloadTask: downloadTask,
            progressSignalInput: progressSignal.input
        )
        
        self.progressSignalsInput.send(value: progressSignal.output)
        
        // Not sure I want this???
//        DispatchQueue.main.asyncAfter(deadline: .now()) {
//            progressSignal.input.send(value: 0.0)
//        }
        return progressSignal.output.producer
    }
    
}


// MARK: - COMPUTED VARS
extension NewDownloadTask {
    
    public private (set) var state: State {
        get {
            self.stateProperty.value
        }
        set {
            self.stateInput.send(value: newValue)
        }
    }
    
    struct ProgressSnapshot {
        let progress: Progress
    }
    
    public var isComplete: Bool {
        self.state.isComplete
    }
    
    public var percentComplete: Double {
        return progress.fractionCompleted
    }
    
    var localFile: LocalFile {
        return remoteFile.localFile
    }
}


// MARK: - OBSERVATIONS
extension NewDownloadTask {
    private func setObservations(
        downloadTask: StorageDownloadTaskInterface,
        progressSignalInput: Signal<Double, Error>.Observer
    ){
        downloadTask.observeInterface(.failure, handler: {
            self.observe($0, progressSignalInput: progressSignalInput)
        })
        downloadTask.observeInterface(.pause, handler: {
            self.observe($0, progressSignalInput: progressSignalInput)
        })
        downloadTask.observeInterface(.resume, handler: {
            self.observe($0, progressSignalInput: progressSignalInput)
        })
        downloadTask.observeInterface(.success, handler: {
            self.observe($0, progressSignalInput: progressSignalInput)
        })
        downloadTask.observeInterface(.progress, handler: {
            self.observe($0, progressSignalInput: progressSignalInput)
        })
        //storageDownloadTask?.observe(.unknown, handler: unknownHandler)
    }
    private func observe(
        _ storageTaskSnapshot: StorageTaskSnapshotInterface,
        progressSignalInput: Signal<Double, Error>.Observer
    ){
        switch storageTaskSnapshot.statusInterface {
        
        case .pause:
            // Have to manually set state to paused because an inner signal's interruption is not bubbled up to the master signal in a flattened operator.
            // Setting state first so testing can verify.
            // This is consistent with how the other observers are set. Since they are set in init, they are called prior to the external signal observer.
            self.state = .paused
            progressSignalInput.sendInterrupted()
            
        case .failure:
            guard let error = storageTaskSnapshot.error
            else { return }
            self.progressSignalsInput.sendCompleted()
            progressSignalInput.send(error: error)
            
        case .progress:
            guard let progress = storageTaskSnapshot.progress
            else { return }
            if childProgress == nil {
                childProgress = progress
            }
            progressSignalInput.send(value: progress.fractionCompleted)
            
        case .resume:
            break
            // Not sure what I want to do here.
//            self.state = .loading
        
        case .success:
            // Signal of Signals must be completed prior to the signal for the completion to bubble up.
            self.progressSignalsInput.sendCompleted()
            progressSignalInput.sendCompleted()
            
        case .unknown: return
        }
    }
    
    private func downloadTaskComplete(url: URL?, error: Error?){
        // !!! DO NOT USE !!!
        // This handler is currently removed when pause is called.
        // Will need to change pause handler to not call removeAllHandlers(), but instead remove the 5 observers individually.
        // Then this can be used.
    }
}


// MARK: - DEFINITIONS
// This will need to be renamed and removed from namespace if this becomes the model for all download tasks.
extension NewDownloadTask {
    enum State: Equatable {
        static func == (
            lhs: NewDownloadTask.State, rhs: NewDownloadTask.State
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
}
