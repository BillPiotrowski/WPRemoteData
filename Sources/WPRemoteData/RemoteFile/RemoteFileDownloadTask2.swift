//
//  File.swift
//  
//
//  Created by William Piotrowski on 1/17/21.
//

import Foundation
import SPCommon
import ReactiveSwift

class NewDownloadTask: NewDownloadTaskProtocol {
    
    private let remoteFile: RemoteFileProtocol
    public var hardRefresh: Bool
    
    public let stateProperty: Property<NewDownloadTaskState>
    private let stateInput: Signal<NewDownloadTaskState, Never>.Observer
    
    public let progressSignal: Signal<Double, Error>
    private let progressInput: Signal<Double, Error>.Observer
    
    // Not sure if second should be Error or Never
//    private var progressSignalsInput: Signal<Signal<Double, Error>, Error>.Observer
    
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
        
        let initialState = NewDownloadTaskState.initialized
        
        let statePipe = Signal<NewDownloadTaskState, Never>.pipe()
        let stateProperty = Property(
            initial: initialState,
            then: statePipe.output
        )
        
//        let progressSignalsPipe = Signal<Signal<Double, Error>, Error>.pipe()
//        let flattenedSignal = progressSignalsPipe.output.flatten(.latest)
        
//        let disposable1 = flattenedSignal.observe(
//            Signal<Signal<Double, Error>.Value, Error>.Observer(
//                value: { val in
//                    statePipe.input.send(value: .loading)
//                }, failed: { error in
//                    statePipe.input.send(value: .failure(error: error))
//                }, completed: {
//                    statePipe.input.send(value: .complete)
//                    statePipe.input.sendCompleted()
//                }, interrupted: {
//                    print("DIDNT THINK INTERRUPTIONS SHOULD BE HERE")
//                    // Does not bubble up to outter from inner signals.
//                }
//            )
//        )
        
        let progressPipe = Signal<Double, Error>.pipe()
        
//        self.progressSignalsInput = progressSignalsPipe.input
        self.progress = progress
        self.hardRefresh = hardRefresh
        self.remoteFile = remoteFile
        self.stateProperty = stateProperty
        self.stateInput = statePipe.input
        self.progressSignal = progressPipe.output
        self.progressInput = progressPipe.input
        
//        self.progressSignal.producer.startWithInterrupted {
//            print("DIDNT THINK 2 INTERRUPTIONS SHOULD BE HERE")
//        }
        
        // MARK: - INIT COMPLETE
        
        let disposable2 = self.stateProperty.producer.startWithValues {
            switch $0 {
            case .paused:
                // REMOVING ALL OBSERVERS WILL CAUSE HANLDER TO NOT BE CALLED. NOT USING YET, SO NOT A BIG DEAL.
//                self.storageDownloadTask?.removeAllObservers()
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
        
//        self.lifecycleDisposable.add(disposable1)
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
        guard hardRefresh || !isLocal
        else {
            progress.completedUnitCount = progress.totalUnitCount
//            self.progressInput.send(value: 1.0)
//            self.progressSignalsInput.sendCompleted()
            self.state = .complete
            return SignalProducer<Double, Error>.init(
                value: self.percentComplete
            )
        }
        
        self.state = .loading
        
        if let downloadTask = self.storageDownloadTask {
            downloadTask.resume()
        } else {
            self.createNew()
        }
        return SignalProducer<Double, Error>.init { (input, lifetime) in
            input.send(value: self.percentComplete)
            let progDisposable = self.progressSignal.observe(input)
            
            let state = self.state
            switch state {
            case .complete: input.sendCompleted()
            case .failure(let error): input.send(error: error)
            case .paused: input.sendCompleted()
            default: break
            }
            
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
        
//        guard let downloadTask = self.storageDownloadTask
//        else {
//            return self.createNew()
//        }
//        return self.resumePrevious(downloadTask: downloadTask)
    }
    
    
    func attemptCancel(){
        self.state = .failure(error: DownloadTaskError.userCancelled)
        self.storageDownloadTask?.cancel()
    }
    func attemptPause(){
        self.state = .paused
        self.storageDownloadTask?.pause()
    }
}



// MARK: - CREATE / RESUME HELPERS
extension NewDownloadTask {
    
    private func createNew() /*-> SignalProducer<Double, Error> */{
//        let progressSignal = Signal<Double, Error>.pipe()
        
        let downloadTask = remoteFile.ref.writeInterface(
            toFile: localFile.url,
            completion: self.downloadTaskComplete
        )
        self.storageDownloadTask = downloadTask
        
        setObservations(
            downloadTask: downloadTask//,
//            progressSignalInput: progressSignal.input
        )
        
//        self.progressSignalsInput.send(value: progressSignal.output)
        
        // Not sure I want this???
//        DispatchQueue.main.asyncAfter(deadline: .now()) {
//            progressSignal.input.send(value: 0.0)
//        }
//        return progressSignal.output.producer
    }
    
}


// MARK: - COMPUTED VARS
extension NewDownloadTask {
    
    public private (set) var state: NewDownloadTaskState {
        get {
            self.stateProperty.value
        }
        set {
            self.stateInput.send(value: newValue)
            switch newValue {
            case .complete:
                self.stateInput.sendCompleted()
                self.progressInput.sendCompleted()
            case .failure(let error):
                self.stateInput.sendCompleted()
                self.progressInput.send(error: error)
            case .initialized: break
            case .loading: break
            case .paused: break
            }
        }
    }
    
    struct ProgressSnapshot {
        let progress: Progress
    }
    
    
    var localFile: LocalFile {
        return remoteFile.localFile
    }
    
    var isLocal: Bool {
        return localFile.exists
    }
}


// MARK: - OBSERVATIONS
extension NewDownloadTask {
    private func setObservations(
        downloadTask: StorageDownloadTaskInterface//,
//        progressSignalInput: Signal<Double, Error>.Observer
    ){
        downloadTask.observeInterface(.failure, handler: self.observe)
        downloadTask.observeInterface(.pause, handler: self.observe)
        downloadTask.observeInterface(.resume, handler: self.observe)
        downloadTask.observeInterface(.success, handler: self.observe)
        downloadTask.observeInterface(.progress, handler:self.observe)
        //storageDownloadTask?.observe(.unknown, handler: unknownHandler)
    }
    private func observe(
        _ storageTaskSnapshot: StorageTaskSnapshotInterface//,
//        progressSignalInput: Signal<Double, Error>.Observer
    ){
        switch storageTaskSnapshot.statusInterface {
        
        case .pause:
            // Have to manually set state to paused because an inner signal's interruption is not bubbled up to the master signal in a flattened operator.
            // Setting state first so testing can verify.
            // This is consistent with how the other observers are set. Since they are set in init, they are called prior to the external signal observer.
            self.state = .paused
//            progressSignalInput.sendInterrupted()
            
        case .failure:
            guard let error = storageTaskSnapshot.error
            else { return }
            self.state = .failure(error: error)
            
            // PUT IN STATE SETTER
//            self.progressSignalsInput.sendCompleted()
//            progressSignalInput.send(error: error)
            
        case .progress:
            guard let progress = storageTaskSnapshot.progress
            else { return }
            if childProgress == nil {
                childProgress = progress
            }
            self.progressInput.send(value: progress.fractionCompleted)
//            progressSignalInput.send(value: progress.fractionCompleted)
            
        case .resume:
            break
            // Not sure what I want to do here.
//            self.state = .loading
        
        case .success:
            self.state = .complete
            
            
            // Signal of Signals must be completed prior to the signal for the completion to bubble up.
//            self.progressSignalsInput.sendCompleted()
//            progressSignalInput.sendCompleted()
            
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

