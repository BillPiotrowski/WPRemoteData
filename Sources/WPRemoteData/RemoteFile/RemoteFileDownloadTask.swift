//
//  RemoteFileDownloadTask.swift
//  RemoteFile
//
//  Created by William Piotrowski on 6/29/20.
//  Copyright © 2020 William Piotrowski. All rights reserved.
//

import SPCommon
//import FirebaseStorage
import ReactiveSwift
import Foundation

public enum DownloadState {
    case initialized
    case downloading
    case paused
    case complete
    case failure(error: Error)
}
public typealias DownloadTaskState = (
    state: DownloadState,
    progress: Progress
)
/// A Protocol to describe individual download tasks. Only responsible for a single item.
public protocol DownloadTaskItem: class {
    //associatedtype T
    var progressSignalProducer: SignalProducer<Progress, Error> { get }
    var downloadStatusProperty: Property<DownloadTaskState> { get }
    var downloadProgress: Progress { get }
    var downloadState: DownloadState { get }
    //var completedSignalProducer: SignalProducer<T, Error> { get}
    func pause()
    func resume()
    func cancel()
    // combine start/nextTask and resume
    // Essentially start. Change to start
    func nextTask()
}

extension DownloadTaskItem {
    internal typealias DownloadTaskSignals = (
        stateInput: Signal<DownloadState, Never>.Observer,
        progressInput: Signal<Progress, Never>.Observer,
        combinedProperty: Property<DownloadTaskState>,
        progressSignalProducer: SignalProducer<Progress, Error>//,
        //completedSignalProducer: SignalProducer<T, Error>,
        //completedInput: Signal<T, Error>.Observer,
//        disposable: Disposable
    )
    static func createSignals() -> DownloadTaskSignals{
        
        // CREATE INITIAL VALUES
        let initialDownloadState = DownloadState.initialized
        let initialProgress = Progress()
        initialProgress.fileOperationKind = .downloading
        initialProgress.totalUnitCount = 1
        initialProgress.fileTotalCount = 1
        
        // CREATE PIPES
        let downloadStatePipe = Signal<DownloadState, Never>.pipe()
        let downloadProgressPipe = Signal<Progress, Never>.pipe()
        
        
        // COMBINE STATE AND PROGRESS INTO A NEW DownloadTaskState
        let combinedSignal = Signal.combineLatest(
            downloadStatePipe.output,
            downloadProgressPipe.output
        ).map{
            (state: $0.0, progress: $0.1)
        }

        // CREATE PROPERTY TO MAINTAIN
        let combinedStateProperty = Property(
            initial: (
                state: initialDownloadState,
                progress: initialProgress
            ),
            then: combinedSignal
        )
        
        // THIS CAN POTENTIALLY BE A COMPUTED VAR?
        let progressSignalProducer: SignalProducer<Progress, Error> = combinedStateProperty.producer
            .promoteError(Error.self).attemptMap({
            switch $0.state {
            case .failure(let error): throw error
            case .complete:
                // creates on complete progress.
                return Self.completedProgress
            default: return $0.progress
            }
        })
        
//        let completedPipe = Signal<T, Error>.pipe()
//        let completedSignalProducer = SignalProducer(completedPipe.output)
//
        // RESENT INITIAL VALUES TO MAKE SURE MERGED PIPE BEGINS
        downloadStatePipe.input.send(value: initialDownloadState)
        downloadProgressPipe.input.send(value: initialProgress)
        
//        let disposable = progressSignalProducer.startWithFailed {
//            completedPipe.input.send(error: $0)
//        }
        
        return (
            downloadStatePipe.input,
            downloadProgressPipe.input,
            combinedStateProperty,
            progressSignalProducer//,
            //completedSignalProducer,
            //completedPipe.input,
//            disposable
        )
    }
    static var completedProgress: Progress {
        let progress = Progress(totalUnitCount: 1)
        progress.completedUnitCount = 1
        return progress
    }
}





public class RemoteFileDownloadTask: DownloadTaskRoot, DownloadTaskItem {
    
    let remoteFile: RemoteFileProtocol
    let localFile: LocalFile
    private var storageDownloadTask: StorageDownloadTaskInterface?
    
    private let downloadStateInput: Signal<DownloadState, Never>.Observer
    private let downloadProgressInput: Signal<Progress, Never>.Observer
    
    /// Stores the current state of the download. A merged value of DownloadState and Progress.
    public let downloadStatusProperty: Property<DownloadTaskState>
    
    /// Produces a sigal of the download task's progress. Can result in error and will complete upon successful download.
    public let progressSignalProducer: SignalProducer<Progress, Error>
    
    //private let completedInput: Signal<URL, Error>.Observer
    
    /// A signal that provides the final completed element Generic.
    //public let completedSignalProducer: SignalProducer<URL, Error>
    
    init(
        remoteFile: RemoteFileProtocol,
        localFile: LocalFile,
        handler: (
            (DownloadTaskRoot.CompletionStatus, DownloadTaskSnapshot) -> Void)? = nil)
    {
        
        let signals = RemoteFileDownloadTask.createSignals()
        
        
        
        
        // HAVE NOT TESTED, BUT SHOULD WORK
//        let disposable = signals.progressSignalProducer.startWithFailed {
//            signals.completedInput.send(error: $0)
//        }
        
        
        
        
        self.remoteFile = remoteFile
        self.localFile = localFile
        self.downloadProgressInput = signals.progressInput
        self.downloadStateInput = signals.stateInput
        self.downloadStatusProperty = signals.combinedProperty
        self.progressSignalProducer = signals.progressSignalProducer
        //self.completedInput = signals.completedInput
        //self.completedSignalProducer = signals.completedSignalProducer
        super.init(handler: handler)
        
        
        // HELPS TO TEST UNTIL THERE IS UNIT TESTING OR MORE ROBUST PROTOCOLS
//        print("NEW DOWNLOAD TASK SIGNAL: \(remoteFile.name)")
//        progressSignalProducer.start(Signal<Progress, Error>.Observer(
//            value: {value in
//                print("DOWNLOAD TASK LOADING: \(remoteFile.name) \(value.fractionCompleted)")
//            },
//            failed: {error in
//                print("DOWNLOAD TASK ERROR: \(error)")
//            },
//            completed: {
//                print("DOWNLOAD TASK COMPLETE")
//            },
//            interrupted: {
//                print("DOWNLOAD TASK INTERUPTED")
//            }
//        ))
    }
    
    convenience init(
        remoteFile: RemoteFileProtocol,
        handler: (
            (DownloadTaskRoot.CompletionStatus, DownloadTaskSnapshot) -> Void)? = nil
    ){
        self.init(
            remoteFile: remoteFile,
            localFile: remoteFile.localFile,
            handler: handler
        )
    }
    
    public override func pause(){
        super.pause()
        storageDownloadTask?.pause()
    }
    public override func resume(){
        super.resume()
        storageDownloadTask?.resume()
    }
    public override func cancel(){
        super.cancel()
        storageDownloadTask?.cancel()
    }
    open override func nextTask(){
        guard hardRefresh || !remoteFile.localFile.exists else {
            // ensure progress is set to complete
            let progress = Progress(totalUnitCount: 1)
            progress.completedUnitCount = 1
            self.downloadState = .complete
            self.downloadProgress = progress
            
            completionStatus = .success(localURL: remoteFile.localFile.url)
            return
        }
        self.downloadState = .downloading
        self.storageDownloadTask = remoteFile.ref.writeInterface(
            toFile: localFile.url,
            completion: self.storageDownloadTaskComplete
        )
        setObservations()
    }
}

extension RemoteFileDownloadTask {
    private func storageDownloadTaskComplete(url: URL?, error: Error?) {
        guard let url = url else {
            let error = error ?? DownloadTaskRoot.DownloadError.noURL
            self.downloadState = .failure(error: error)
            completionStatus = .failure(error: error)
            return
        }
        self.downloadState = .complete
        //self.completedInput.send(value: url)
        completionStatus = .success(localURL: url)
    }
}

// MARK: OBSERVATIONS
extension RemoteFileDownloadTask {
    private func setObservations(){
        storageDownloadTask?.observeInterface(.failure, handler: self.observe(_:))
        storageDownloadTask?.observeInterface(.pause, handler: self.observe(_:))
        storageDownloadTask?.observeInterface(.resume, handler: self.observe(_:))
        storageDownloadTask?.observeInterface(.success, handler: self.observe(_:))
        storageDownloadTask?.observeInterface(.progress, handler: self.observe(_:))
        //storageDownloadTask?.observe(.unknown, handler: unknownHandler)
    }
    private func observe(
        _ storageTaskSnapshot: StorageTaskSnapshotInterface
    ){
        switch storageTaskSnapshot.statusInterface {
        case .pause:
            self.downloadState = .paused
            return
        case .failure:
            guard let error = storageTaskSnapshot.error
            else { return }
            self.downloadState = .failure(error: error)
            return
        case .progress:
            guard let progress = storageTaskSnapshot.progress
            else { return }
            self.downloadProgress = progress
            // REMOVE THIS EVENTUALLY!
            self.progress.totalUnitCount = progress.totalUnitCount
            self.progress.completedUnitCount = progress.completedUnitCount
            callObservers(.progress, storageTaskSnapshot: storageTaskSnapshot)
        case .resume:
            self.downloadState = .downloading
        case .success:
            self.downloadState = .complete
        case .unknown: return
        }
    }
}

// MARK: DEPRECATED ????? CALL TO OBSERVERS
extension RemoteFileDownloadTask {
    private func callObservers(_ status: RemoteFileDownloadTask.Observable){
        callObservers(status, downloadTaskSnapshot: self.snapshot)
    }
    private func callObservers(_ status: RemoteFileDownloadTask.Observable, storageTaskSnapshot: StorageTaskSnapshotInterface){
        callObservers(status, downloadTaskSnapshot: snapshot)
    }
}

// MARK: COMPUTED VAR HELPERS
extension RemoteFileDownloadTask {
    public private (set) var downloadProgress: Progress {
        get { return downloadStatusProperty.value.progress }
        set {
            self.downloadProgressInput.send(value: newValue)
            guard newValue.isFinished else { return }
            self.downloadProgressInput.sendCompleted()
        }
    }
    public private (set) var downloadState: DownloadState {
        get { return downloadStatusProperty.value.state }
        set {
            self.downloadStateInput.send(value: newValue)
            guard case .complete = newValue else { return }
            self.downloadStateInput.sendCompleted()
        }
    }
}

