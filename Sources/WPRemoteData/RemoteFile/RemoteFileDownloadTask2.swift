//
//  File.swift
//  
//
//  Created by William Piotrowski on 1/17/21.
//

import Foundation

import SPCommon
//import FirebaseStorage
import ReactiveSwift
import Foundation









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
    
//    public private (set) let state: DownloadState
    public private (set) var progress: Progress
    
    private var storageDownloadTask: StorageDownloadTaskInterface? = nil
    
    init(
//        storageDownloadTask: StorageDownloadTaskInterface,
        remoteFile: RemoteFileProtocol,
//        localFile: LocalFile, // PReferable OpenableLocalFile generic.,
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
        
//        let (lettersSignal, lettersObserver) = Signal<String, Never>.pipe()
//        let (numbersSignal, numbersObserver) = Signal<String, Never>.pipe()
//        let (signal, observer) = Signal<Signal<String, Never>, Never>.pipe()
        
        

        // Not sure if second should be Error or Never
        let progressSignalsPipe = Signal<Signal<Double, Error>, Error>.pipe()
        let flattenedSignal = progressSignalsPipe.output.flatten(.latest)
        
        flattenedSignal.observe(
            Signal<Signal<Double, Error>.Value, Error>.Observer(
                value: { val in
                    statePipe.input.send(value: .loading)
                }, failed: { error in
                    statePipe.input.send(value: .failure(error: error))
                }, completed: {
                    statePipe.input.send(value: .complete)
                }, interrupted: {
                    statePipe.input.send(value: .paused)
                }
            )
        )
        
        
        
        
        self.progressSignalsInput = progressSignalsPipe.input
        self.progress = progress
        self.hardRefresh = hardRefresh
        self.remoteFile = remoteFile
        self.stateProperty = stateProperty
        self.stateInput = statePipe.input
        
        
    }
    
    var localFile: LocalFile {
        return remoteFile.localFile
    }
    
    
    
    
    
    // Start creates a new signal and returns it / or producer.
    // when state changes the state new value setter checks for pause -> interrupts. and completions and errors.
    
    /// Returns a Signal Producer with the Double indicating percentage complete from 0.0 to 1.0
    ///
    /// If there file is local and hardRefresh is set to false, it will immediately return a completed event.
    func start() -> SignalProducer<Double, Error> {
        // ADD CHECK FOR IS COMPLETE!
        guard hardRefresh || !localFile.exists /* || !isComplete*/ else {
            
//            let signal = Signal<State, Never>.pipe()
            
            // ensure progress is set to complete
            let progress = Progress(totalUnitCount: 1)
            progress.completedUnitCount = 1
            self.state = .complete
//            self.downloadProgress = progress
            
//            completionStatus = .success(localURL: remoteFile.localFile.url)
            return SignalProducer<Double, Error>.init(value: 1)
//            return
        }
//        self.downloadState = .downloading
        self.state = .loading
        let downloadTask = remoteFile.ref.writeInterface(
            toFile: localFile.url,
            completion: self.downloadTaskComplete
        )
        self.storageDownloadTask = downloadTask
        
        let progressSignal = Signal<Double, Error>.pipe()
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
        
//        return stateProperty.producer.attemptMap { response throws -> Double? in
//            switch response {
//            case .failure(let error): throw error
//            case .loading(let progress): return progress.progress.fractionCompleted
//            default: return nil
//            }
//        }.compactMap{
//            return $0
//        }
        
    }
    func cancel(){
        self.storageDownloadTask?.cancel()
    }
    func pause(){
        self.storageDownloadTask?.pause()
    }
    
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
            progressSignalInput.sendInterrupted()
            return
        case .failure:
            guard let error = storageTaskSnapshot.error
            else { return }
            print("ERROR!!!: \(error)")
            progressSignalInput.send(error: error)
            return
        case .progress:
            guard let progress = storageTaskSnapshot.progress
            else { return }
            
            if childProgress == nil {
                childProgress = progress
            }
            
            progressSignalInput.send(value: progress.fractionCompleted)
            
            self.state = .loading
            // REMOVE THIS EVENTUALLY!
            
            // CAN I ADD PROGRESS AS CHILD OF MAIN PROGRESS?
            // INSTEAD OF UPDATING MANUALLY?
//            self.progress.
//            self.progress.totalUnitCount = progress.totalUnitCount
//            self.progress.completedUnitCount = progress.completedUnitCount
//            callObservers(.progress, storageTaskSnapshot: storageTaskSnapshot)
        case .resume:
            self.state = .loading
//            self.downloadState = .
        case .success:
            // MUST BE CALLED FIRST
            self.progressSignalsInput.sendCompleted()
            progressSignalInput.sendCompleted()
//            self.state = .complete
        case .unknown: return
        }
    }
    
    private func downloadTaskComplete(url: URL?, error: Error?){
        guard let url = url
        else {
            self.state = .failure(error: error ?? NSError(
                domain: "No url and no error?",
                code: 3
            ))
            return
        }
        self.state = .complete
    }
    
    public private (set) var state: State {
        get {
            self.stateProperty.value
        } set {
//            self.stateInput.send(value: newValue)
//            guard case .complete = newValue
//            else { return }
//            self.stateInput.sendCompleted()
            // SET PROGRESS TO ENSURE IT IS COMPLETE
        }
    }
    
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
    
    
    struct ProgressSnapshot {
        let progress: Progress
    }
    
    public var isComplete: Bool {
        self.state.isComplete
    }
    
}

/*
class StorageDownloadObserver {
    private weak var signal: Signal<Double, Error>.Observer
    private weak var downloadTask: StorageDownloadTaskInterface
    
    init(
        signal: Signal<Double, Error>.Observer,
        downloadTask: StorageDownloadTaskInterface
    ){
        self.signal = signal
        self.downloadTask = downloadTask
    }
    
}

*/















