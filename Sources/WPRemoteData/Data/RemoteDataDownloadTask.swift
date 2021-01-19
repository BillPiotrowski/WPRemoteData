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

public class RemoteDataDownloadTask<
    RemoteDoc: RemoteDataDownloadableDocument
> {
    public let stateProperty: Property<NewDownloadTaskState>
    private let stateInput: Signal<NewDownloadTaskState, Never>.Observer
    
    public private (set) var progress: Progress
    
    public var state: NewDownloadTaskState { self.stateProperty.value }
    
    private let localFile: RemoteDoc.LocalDoc
    
    public var isLocal: Bool {
        return localFile.exists
    }
    
    public var hardRefresh: Bool
    
    public var remoteDataDocument: RemoteDoc
    
    
    
    
    
    
    
    let disposable = CompositeDisposable()
    
    
    fileprivate init(
        remoteDataDocument: RemoteDoc,
        localFile: RemoteDoc.LocalDoc,
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
        
        
        
        
        
        self.hardRefresh = hardRefresh
        
        self.stateProperty = stateProperty
        self.stateInput = statePipe.input
        self.progress = progress
        self.remoteDataDocument = remoteDataDocument
        self.localFile = localFile
        
    }
}



extension RemoteDataDownloadTask: NewDownloadTaskProtocol where
    RemoteDoc.Data == RemoteDoc.LocalDoc.O,
    RemoteDoc.Data.RemoteDoc == RemoteDoc,
    RemoteDoc.LocalDoc == RemoteDoc.LocalDoc.O.File,
    RemoteDoc.LocalDoc.O: LocalOpenableData
{
    convenience init(
        remoteDataDocument: RemoteDoc
    ){
        self.init(
            remoteDataDocument: remoteDataDocument,
            localFile: remoteDataDocument.localDocument
        )
    }
    
    public func start() -> SignalProducer<Double, Error> {
        guard !self.isComplete
        else {
            return SignalProducer<Double, Error>.init(
                value: self.percentComplete
            )
        }
        guard hardRefresh || !isLocal
        else {
            progress.completedUnitCount = progress.totalUnitCount
//            self.progressSignalsInput.sendCompleted()
            self.stateInput.send(value: .complete)
            return SignalProducer<Double, Error>.init(
                value: self.percentComplete
            )
        }
        
        
        let signalPipe = Signal<Double, Error>.pipe()
        
        // LOADING WILL NEVER SEND
//        self.stateInput.send(value: .loading)
        
        self.remoteDataDocument.download()
        .then { [unowned self] doc in
            self.progress.completedUnitCount = self.progress.totalUnitCount
            self.stateInput.send(value: .complete)
            self.stateInput.sendCompleted()
            signalPipe.input.send(value: 1.0)
            signalPipe.input.sendCompleted()
        }.catch { error in
            self.stateInput.send(value: .failure(error: error))
            signalPipe.input.send(error: error)
        }
        return signalPipe.output.producer
    }
}



extension RemoteDataDownloadTask {
    public func attemptPause() {
        // Could potentially stop the writing of the file to local?
        return
    }
    
    public func attemptCancel() {
        // Could potentially stop the writing of the file to local?
        return
    }
}
