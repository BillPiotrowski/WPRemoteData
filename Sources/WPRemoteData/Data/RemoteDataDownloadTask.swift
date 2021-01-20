//
//  RemoteDataDownloadTask.swift
//  Scorepio
//
//  Created by William Piotrowski on 12/2/19.
//  Copyright © 2019 William Piotrowski. All rights reserved.
//

import Foundation
import SPCommon
import ReactiveSwift

/// Class for downloading a RemoteDoc.
///
/// This has generic constraints for RemoteDoc and RemoteDoc.LocalDoc
///
/// Conformts to: `NewDownloadTaskProtocol`.
public class RemoteDataDownloadTask<
    RemoteDoc: RemoteDataDownloadableDocument
> where
    RemoteDoc.Data == RemoteDoc.LocalDoc.O,
    RemoteDoc.Data.RemoteDoc == RemoteDoc,
    RemoteDoc.LocalDoc == RemoteDoc.LocalDoc.O.File,
    RemoteDoc.LocalDoc.O: LocalOpenableData
{
    private let stateInput: Signal<NewDownloadTaskState, Never>.Observer
    public let stateProperty: Property<NewDownloadTaskState>
    
    private let progressInput: Signal<Double, Error>.Observer
    public let progressSignal: Signal<Double, Error>
    
    public private (set) var progress: Progress
    public var hardRefresh: Bool
    private let disposable = CompositeDisposable()
    
    private let localFile: RemoteDoc.LocalDoc
    private var remoteDataDocument: RemoteDoc
    
    init(
        remoteDataDocument: RemoteDoc,
        hardRefresh: Bool? = nil
    ){
        let hardRefresh = hardRefresh ?? NewGroupDownloadTask.defaultHardRefresh
        let progress: Progress = Progress()
        progress.fileOperationKind = .downloading
        progress.totalUnitCount = Int64(1)
        
        let initialState = NewDownloadTaskState.initialized
        
        let statePipe = Signal<NewDownloadTaskState, Never>.pipe()
        let stateProperty = Property(
            initial: initialState,
            then: statePipe.output
        )
        
        let pipe = Signal<Double, Error>.pipe()
        
        self.progressInput = pipe.input
        self.hardRefresh = hardRefresh
        self.progressSignal = pipe.output
        self.stateProperty = stateProperty
        self.stateInput = statePipe.input
        self.progress = progress
        self.remoteDataDocument = remoteDataDocument
        self.localFile = remoteDataDocument.localDocument
        
    }
}

extension RemoteDataDownloadTask: NewDownloadTaskProtocol where
    RemoteDoc.Data == RemoteDoc.LocalDoc.O,
    RemoteDoc.Data.RemoteDoc == RemoteDoc,
    RemoteDoc.LocalDoc == RemoteDoc.LocalDoc.O.File,
    RemoteDoc.LocalDoc.O: LocalOpenableData
{
//    convenience init(
//        remoteDataDocument: RemoteDoc,
//
//    ){
//        self.init(
//            remoteDataDocument: remoteDataDocument,
//            localFile: remoteDataDocument.localDocument
//        )
//    }
}

// MARK: - START
extension RemoteDataDownloadTask {
    public func start() -> SignalProducer<Double, Error> {
        guard !self.isTerminated else {
            return self.progressSignalProducer
        }
        guard hardRefresh || !isLocal else {
            progress.completedUnitCount = progress.totalUnitCount
            self.state = .complete
            return self.progressSignalProducer
        }
        
        self.state = .loading
        
        // weak self is required for testing. Will retain otherwise.
        self.remoteDataDocument.download()
        .then { [weak self] doc in
            
            // 1) Complete Progress object
            self?.progress.completedUnitCount = self?.progress.totalUnitCount ?? 1
            
            // 2) Send Progress value to subscribers
            self?.progressInput.send(value: 1.0)
            
            // 3) Set state, which will terminate state & progress signals.
            self?.state = .complete
            
        }.catch { [weak self] error in
            self?.state = .failure(error: error)
        }
        
        return self.progressSignalProducer
    }
}

// MARK: - PAUSE / CANCEL
extension RemoteDataDownloadTask {
    public func attemptPause() {
        self.state = .paused
        // Could potentially stop the writing of the file to local?
        return
    }
    
    public func attemptCancel() {
        self.state = .failure(error: DownloadTaskError.userCancelled)
        // Could potentially stop the writing of the file to local?
        return
    }
}

// MARK: - STATE
extension RemoteDataDownloadTask {
    
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
}

// MARK: - COMPUTED VARS
extension RemoteDataDownloadTask {
    
    public var isLocal: Bool { localFile.exists }
}
