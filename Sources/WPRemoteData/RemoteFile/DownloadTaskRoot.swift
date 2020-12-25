    //
//  DownloadTask.swift
//  RemoteFile
//
//  Created by William Piotrowski on 6/29/20.
//  Copyright © 2020 William Piotrowski. All rights reserved.
//
/*
import SPCommon
import ReactiveSwift

open class DownloadTaskRoot: DownloadTaskProtocol {
    public let uid: String
    public var hardRefresh: Bool = false
    var state: DownloadTaskRoot.State = .initialized
    var completedTasks: [DownloadTaskSnapshot] = []
    private var observers: [String: DownloadTaskRoot.Observer] = [:]
    public var completionCallback: ((DownloadTaskRoot.CompletionStatus, DownloadTaskSnapshot) -> Void)?
    public let progress: Progress = Progress()
    // make so it's only changable from completion status / completeTask
    private var error: Error? = nil
    public var currentChildTask: DownloadTaskProtocol? = nil {
        didSet {
            currentChildTask?.hardRefresh = self.hardRefresh
            currentChildTask?.completionCallback = childTaskCompletion
            setObservations(remoteFileDownloadTask: currentChildTask)
        }
    }
    /// Once a value of success or failure is defined, it can not be changed.
    public var completionStatus: DownloadTaskRoot.CompletionStatus? = nil {
        didSet(previousValue) {
            switch previousValue {
            case .none:
                guard let completionStatus = completionStatus else { return }
                switch completionStatus {
                case .failure(let error):
                    self.progressInput.send(error: error)
                case .success:
                    self.progressInput.sendCompleted()
                }
                completeTask(completionStatus: completionStatus)
            case .some(let previousValue):
                print("PREVENTED CHANGE IN COMPLETION STATUS!")
                completionStatus = previousValue
            }
        }
    }
    public let progressSignal: Signal<Double, Error>
    private let progressInput: Signal<Double, Error>.Observer
    //let progressProperty: Property<Double>
    
    public init(
        handler: ((DownloadTaskRoot.CompletionStatus, DownloadTaskSnapshot) -> Void)? = nil
    ){
        let signal = Signal<Double, Error>.pipe()
        
        self.progressInput = signal.input
        self.progressSignal = signal.output
        //self.progressProperty = Property(initial: 0, then: signal.output)
        self.completionCallback = handler
        self.progress.fileOperationKind = .downloading
        self.uid = UUID().uuidString
        
        // SET OBSERVER TO UPDATE PROGRESS SIGNAL
        _ = self.observe(.progress){ snapshot in
            self.progressInput.send(
                value: snapshot.progress.fractionCompleted
            )
        }
    }
    
    private func childTaskCompletion(
        completionStatus: DownloadTaskRoot.CompletionStatus,
        snapshot: DownloadTaskSnapshot
    ){
        switch completionStatus {
        case .failure: self.completionStatus = completionStatus
        case .success: self.nextTask()
        }
        guard let previousTask = currentChildTask else { return }
        completedTasks.append(previousTask.snapshot)
    }
    open func nextTask(){
        
    }
    
    public func pause(){
        currentChildTask?.pause()
        state = .paused
    }
    public func resume(){
        currentChildTask?.resume()
        state = .loading
    }
    public func cancel(){
        currentChildTask?.cancel()
    }
    public func begin(){
        state = .loading
        nextTask()
    }
}

extension DownloadTaskRoot {
    public var snapshot: DownloadTaskSnapshot {
        return DownloadTaskSnapshot(
            progress: progress,
            error: nil,
            task: self,
            currentChildTask: currentChildTask,
            completedChildTaskSnapshots: completedTasks
        )
    }
    
    private func completeTask(completionStatus: DownloadTaskRoot.CompletionStatus){
        // NOT SURE THAT THIS FUNCTIONS!!!
        if (!progress.isFinished){
            progress.completedUnitCount = progress.totalUnitCount
        }
        currentChildTask = nil
        switch completionStatus {
        case .success: callObservers(.success, downloadTaskSnapshot: snapshot)
        case .failure(let error):
            self.error = error
            callObservers(.failure, downloadTaskSnapshot: snapshot)
        }
        removeAllObservers()
        guard let handler = completionCallback else { return }
        handler(completionStatus, snapshot)
    }
}

// PRIVATE OBSERVATION FUNCTIONS
extension DownloadTaskRoot {
    private func filterObservers(type: DownloadTaskRoot.Observable) -> [String: DownloadTaskRoot.Observer]{
        return observers.filter { (uid, observer) -> Bool in
            return observer.type == type
        }
    }
    private func setObservations(remoteFileDownloadTask: DownloadTaskProtocol?){
        _ = remoteFileDownloadTask?.observe(.failure, handler: failureHandler)
        _ = remoteFileDownloadTask?.observe(.pause, handler: pauseHandler)
        _ = remoteFileDownloadTask?.observe(.resume, handler: resumeHandler)
        _ = remoteFileDownloadTask?.observe(.success, handler: successHandler)
        //_ = storageDownloadTask?.observe(.unknown, handler: unknownHandler)
        _ = remoteFileDownloadTask?.observe(.progress, handler: progressHandler)
    }
    private func failureHandler(_ downloadTaskSnapshot: DownloadTaskSnapshot){
        //callObservers(.failure, downloadTaskSnapshot: downloadTaskSnapshot)
    }
    private func pauseHandler(_ downloadTaskSnapshot: DownloadTaskSnapshot){
        //callObservers(.pause, downloadTaskSnapshot: downloadTaskSnapshot)
    }
    private func resumeHandler(_ downloadTaskSnapshot: DownloadTaskSnapshot){
        //callObservers(.resume, downloadTaskSnapshot: downloadTaskSnapshot)
    }
    private func successHandler(_ downloadTaskSnapshot: DownloadTaskSnapshot){
        //callObservers(.success, downloadTaskSnapshot: downloadTaskSnapshot)
    }
    private func unknownHandler(_ downloadTaskSnapshot: DownloadTaskSnapshot){
        
    }
    private func progressHandler(_ downloadTaskSnapshot: DownloadTaskSnapshot){
        self.progressInput.send(value: downloadTaskSnapshot.progress.fractionCompleted)
        callObservers(.progress, downloadTaskSnapshot: self.snapshot)
        //print("Total Progress: \(self.progress.fractionCompleted)")
    }
}

// PUBLIC OBERSVATION FUNCTIONS
extension DownloadTaskRoot {
    public func removeObserver(withHandle: String){
        observers.removeValue(forKey: withHandle)
    }
    
    /// Would remove all of a particular observation status. Does not currently function
    ///
    /// - Parameter for: the observable type to be removed.
    public func removeAllObservers(for: DownloadTaskRoot.Observable){
        
    }
    
    // Remove all observers
    public func removeAllObservers(){
        observers.removeAll()
    }
    public func observe (_ status: DownloadTaskRoot.Observable, handler: @escaping (_ snapshot: DownloadTaskSnapshot) -> Void) -> String {
        let uid = UUID().uuidString
        observers[uid] = DownloadTaskRoot.Observer(type: status, handler: handler)
        //setProgressObservation()
        return uid
    }
    func callObservers(_ status: DownloadTaskRoot.Observable, downloadTaskSnapshot: DownloadTaskSnapshot){
        let filteredObservers = filterObservers(type: status)
        for observerItem in filteredObservers {
            observerItem.value.handler(downloadTaskSnapshot)
        }
    }
}

// DEFINITIONS
extension DownloadTaskRoot {
    public enum CompletionStatus {
        case success(localURL: URL?)
        case failure(error: Error)
    }
    public enum Observable {
        case resume
        case pause
        case progress
        case success
        case failure
    }
    public struct Observer {
        let type: DownloadTaskRoot.Observable
        let handler: (_ snapshot: DownloadTaskSnapshot) -> Void
    }
    enum DownloadError: ScorepioError {
        case noURL
        
        var message: String {
            switch self {
            case .noURL: return "Unknown error on download. No URL or error returned."
            }
        }
    }
    enum State {
        case initialized
        case loading
        case paused
        case success(url: URL)
        case failure(error: Error)
    }
}


*/
