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

public class RemoteDataDownloadTask: DownloadTaskRoot, DownloadTaskItem {
    public var temp: URL.Type = URL.self
    
    let remoteData: LocallyArchivableRemoteDataReference
    
    
    
    private let downloadStateInput: Signal<DownloadState, Never>.Observer
    private let downloadProgressInput: Signal<Progress, Never>.Observer
    
    /// Stores the current state of the download. A merged value of DownloadState and Progress.
    public let downloadStatusProperty: Property<DownloadTaskState>
    
    /// Produces a sigal of the download task's progress. Can result in error and will complete upon successful download.
    public let progressSignalProducer: SignalProducer<Progress, Error>
    
//    private let completedInput: Signal<URL, Error>.Observer
    
    /// A signal that provides the final completed element Generic.
//    public let completedSignalProducer: SignalProducer<URL, Error>
    
    let disposable = CompositeDisposable()
    
    
    init(
        remoteDataProtocol: LocallyArchivableRemoteDataReference,
        handler: ((DownloadTaskRoot.CompletionStatus, DownloadTaskSnapshot) -> Void)? = nil
    ){
        
        
        let signals = RemoteFileDownloadTask.createSignals()
        
        
        
        
        // HAVE NOT TESTED, BUT SHOULD WORK
//        let disposable = signals.progressSignalProducer.startWithFailed {
//            signals.completedInput.send(error: $0)
//        }

        
        
        
        self.downloadProgressInput = signals.progressInput
        self.downloadStateInput = signals.stateInput
        self.downloadStatusProperty = signals.combinedProperty
        self.progressSignalProducer = signals.progressSignalProducer
//        self.completedInput = signals.completedInput
//        self.completedSignalProducer = signals.completedSignalProducer
        self.remoteData = remoteDataProtocol
        super.init(handler: handler)
        progress.totalUnitCount = 1
        
        
        // HELPS TO TEST UNTIL THERE IS UNIT TESTING OR MORE ROBUST PROTOCOLS
//        print("NEW DATA DOWNLOAD TASK SIGNAL: \(remoteData.documentID)")
//        progressSignalProducer.start(Signal<Progress, Error>.Observer(
//            value: {value in
//                print("DATA DOWNLOAD TASK LOADING: \(self.remoteData.documentID) \(value.fractionCompleted)")
//            },
//            failed: {error in
//                print("DATA DOWNLOAD TASK ERROR: \(error)")
//            },
//            completed: {
//                print("DATA DOWNLOAD TASK COMPLETE")
//            },
//            interrupted: {
//                print("DATA DOWNLOAD TASK INTERUPTED")
//            }
//        ))
        
    }
    
    convenience init(
        remoteData: LocallyArchivableRemoteDataReference,
        handler: ((DownloadTaskRoot.CompletionStatus, DownloadTaskSnapshot) -> Void)? = nil
    ){
        self.init(remoteDataProtocol: remoteData, handler: handler)
    }
    
    override public func nextTask() {
        remoteData.download()
        .done { data in
            let localURL = self.remoteData.localFileReference.url
            // CAN EVENTUALLY SEND DATA?
//            self.completedInput.send(value: localURL)
            self.downloadState = .complete
            self.completionStatus = .success(localURL: localURL)
        }
        .catch { error in
            self.downloadState = .failure(error: error)
            self.completionStatus = .failure(error: error)
        }
        //remoteData.getToLocal(completionHandler: getToLocalCallback)
    }
}

/*
extension RemoteDataDownloadTask {
    private func getToLocalCallback(response: RemoteDataType.GetResponse, error: Error?) {
        guard let localURL = response.document?.serverDocument.localFile.url else {
            completionStatus = .failure(error: error ?? DownloadTaskRoot.DownloadError.noURL)
            return
        }
        completionStatus = .success(localURL: localURL)
    }
}
*/

// MARK: COMPUTED VAR HELPERS
extension RemoteDataDownloadTask {
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
            self.downloadProgressInput.sendCompleted()
            self.downloadStateInput.sendCompleted()
        }
    }
}

