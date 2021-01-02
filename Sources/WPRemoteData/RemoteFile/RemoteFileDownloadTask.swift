//
//  RemoteFileDownloadTask.swift
//  RemoteFile
//
//  Created by William Piotrowski on 6/29/20.
//  Copyright © 2020 William Piotrowski. All rights reserved.
//

import SPCommon
import FirebaseStorage

public class RemoteFileDownloadTask: DownloadTaskRoot {
    let remoteFile: RemoteFileProtocol
    let localFile: LocalFileReference
    private var storageDownloadTask: StorageDownloadTask?
    
    init(
        remoteFile: RemoteFileProtocol,
        localFile: LocalFileReference,
        handler: (
            (DownloadTaskRoot.CompletionStatus, DownloadTaskSnapshot) -> Void)? = nil)
    {
        self.remoteFile = remoteFile
        self.localFile = localFile
        super.init(handler: handler)
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
            completionStatus = .success(localURL: remoteFile.localFile.url)
            return
        }
        self.storageDownloadTask = remoteFile.ref.write(toFile: localFile.url, completion: self.storageDownloadTaskComplete)
        setObservations()
    }
}

extension RemoteFileDownloadTask {
    private func storageDownloadTaskComplete(url: URL?, error: Error?) {
        guard let url = url else {
            completionStatus = .failure(error: error ?? DownloadTaskRoot.DownloadError.noURL)
            return
        }
        completionStatus = .success(localURL: url)
    }
}

// OBSERVE
extension RemoteFileDownloadTask {
    private func setObservations(){
        storageDownloadTask?.observe(.failure, handler: failureHandler)
        storageDownloadTask?.observe(.pause, handler: pauseHandler)
        storageDownloadTask?.observe(.resume, handler: resumeHandler)
        storageDownloadTask?.observe(.success, handler: successHandler)
        storageDownloadTask?.observe(.progress, handler: progressHandler)
        //storageDownloadTask?.observe(.unknown, handler: unknownHandler)
    }
    private func failureHandler(_ storageTaskSnapshot: StorageTaskSnapshot){
        //self.error = storageTaskSnapshot.error
        //callObservers(.failure, storageTaskSnapshot: storageTaskSnapshot)
    }
    private func pauseHandler(_ storageTaskSnapshot: StorageTaskSnapshot){
        //callObservers(.pause, storageTaskSnapshot: storageTaskSnapshot)
    }
    private func resumeHandler(_ storageTaskSnapshot: StorageTaskSnapshot){
        //callObservers(.resume, storageTaskSnapshot: storageTaskSnapshot)
    }
    private func successHandler(_ storageTaskSnapshot: StorageTaskSnapshot){
        //callObservers(.success, storageTaskSnapshot: storageTaskSnapshot)
    }
    private func unknownHandler(_ storageTaskSnapshot: StorageTaskSnapshot){
        
    }
    private func progressHandler(_ storageTaskSnapshot: StorageTaskSnapshot){
        guard let snapshotProgress = storageTaskSnapshot.progress else { return }
        self.progress.totalUnitCount = snapshotProgress.totalUnitCount
        self.progress.completedUnitCount = snapshotProgress.completedUnitCount
        callObservers(.progress, storageTaskSnapshot: storageTaskSnapshot)
    }
    
    private func callObservers(_ status: RemoteFileDownloadTask.Observable){
        callObservers(status, downloadTaskSnapshot: self.snapshot)
    }
    private func callObservers(_ status: RemoteFileDownloadTask.Observable, storageTaskSnapshot: StorageTaskSnapshot){
        callObservers(status, downloadTaskSnapshot: snapshot)
    }
}

