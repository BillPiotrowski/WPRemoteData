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
        
        let progressPipe = Signal<Double, Error>.pipe()
        
        self.progress = progress
        self.hardRefresh = hardRefresh
        self.remoteFile = remoteFile
        self.stateProperty = stateProperty
        self.stateInput = statePipe.input
        self.progressSignal = progressPipe.output
        self.progressInput = progressPipe.input
        
        // MARK: - INIT COMPLETE
        
        let disposable2 = self.stateProperty.producer.startWithValues {
            switch $0 {
                
            case .complete, .failure:
                // These are not required, but cleaning up.
                self.storageDownloadTask?.removeAllObservers()
                self.storageDownloadTask = nil
                
                // !!! REQUIRED: !!!
                self.lifecycleDisposable.dispose()
                break
                
            case .loading, .initialized, .paused: break
            }
        }
        
        self.lifecycleDisposable.add(disposable2)
    }
    
}

// MARK: - PUBLIC METHODS
extension NewDownloadTask {
    
    func start() -> SignalProducer<Double, Error> {
        guard !self.isTerminated else {
            return self.progressSignalProducer
        }
        guard hardRefresh || !isLocal else {
            progress.completedUnitCount = progress.totalUnitCount
            self.state = .complete
            return self.progressSignalProducer
        }
        
        self.state = .loading
        
        if let downloadTask = self.storageDownloadTask {
            downloadTask.resume()
        } else {
            self.createNew()
        }
        
        return self.progressSignalProducer
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
    
    /// Creates new download task and sets it at the class variable.
    ///
    /// Sets all observers.
    private func createNew() {
        
        let downloadTask = remoteFile.ref.writeInterface(
            toFile: localFile.url,
            completion: self.downloadTaskComplete
        )
        self.storageDownloadTask = downloadTask
        
        setObservations(
            downloadTask: downloadTask
        )
    }
    
}


// MARK: - COMPUTED VARS
extension NewDownloadTask {
    
    /// Gets and sets the state property. When set to complete or error, the progress signal is completed or failed respectively.
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
        downloadTask: StorageDownloadTaskInterface
    ){
        downloadTask.observeInterface(.failure, handler: self.observe)
//        downloadTask.observeInterface(.pause, handler: self.observe)
//        downloadTask.observeInterface(.resume, handler: self.observe)
        downloadTask.observeInterface(.success, handler: self.observe)
        downloadTask.observeInterface(.progress, handler:self.observe)
    }
    private func observe(
        _ storageTaskSnapshot: StorageTaskSnapshotInterface
    ){
        switch storageTaskSnapshot.statusInterface {
        
        case .pause:
            // Setting state here would be redundant because state is set to pause immediately on pause() method.
            // This could cause an issue if user pauses resumes prior to this event triggering, so leaving out.
            // self.state = .paused
            break
            
        case .failure:
            guard let error = storageTaskSnapshot.error
            else { return }
            self.state = .failure(error: error)
            
        case .progress:
            guard let progress = storageTaskSnapshot.progress
            else { return }
            
            // The first Progress update that is sent is set as a child of this class's Progress.
            if childProgress == nil {
                childProgress = progress
            }
            self.progressInput.send(value: progress.fractionCompleted)
            
        case .resume: break
            
        case .success:
            self.state = .complete
            
        case .unknown: return
        }
    }
    
    private func downloadTaskComplete(url: URL?, error: Error?){
    }
}

