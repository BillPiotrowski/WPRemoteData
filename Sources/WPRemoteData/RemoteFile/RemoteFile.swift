//
//  RemoteFile.swift
//  RemoteFile
//
//  Created by William Piotrowski on 6/28/20.
//  Copyright © 2020 William Piotrowski. All rights reserved.
//

import Foundation
import SPCommon




// IS THIS NECESSARY???
public protocol RemoteFileProtocol: RemoteDataItem, RemoteDownloadable {
    var location: RemoteFileFolderProtocol { get }
    var name: String { get }
    var localFile: LocalFile { get }
//    init(remoteFileFolder: RemoteFileFolderProtocol, file: String) throws
}

// MARK: - CONFORM: RemoteDataItem
extension RemoteFileProtocol {
    public var parentPathArray: [String] {
        return location.pathArray
    }
}







public protocol RemoteFileVariableChild: RemoteFileProtocol {
    associatedtype RemoteLocation: RemoteFileFolderGettableChildren
    var remoteLocation: RemoteLocation { get }
    init(remoteLocation: RemoteLocation, name: String)
}
extension RemoteFileVariableChild {
    public var location: RemoteFileFolderProtocol {
        remoteLocation
    }
}








public protocol RemoteDownloadable {
    var downloadTaskProtocol: DownloadTaskProtocol { get }
}

extension RemoteFileProtocol {
    
    public var isLocal: Bool {
        return localFile.exists
    }
}













extension RemoteFileProtocol /*: RemoteDownloadable*/ {
    // SHOULD NOT BE PUBLIC!
    public var ref: StorageReferenceInterface {
        return location.locationInterface.childInterface(name)
    }
    public var downloadTaskProtocol: DownloadTaskProtocol {
        return downloadTask
    }
    static func writeToLocal(
        storageDocument: RemoteFileProtocol,
        localDocument: LocalFile,
        handler: ((DownloadTaskRoot.CompletionStatus, DownloadTaskSnapshot) -> Void)? = nil
    ) -> RemoteFileDownloadTask {
        let downloadTask = Self.downloadTask(
            storageDocument: storageDocument,
            localDocument: localDocument,
            handler: handler
        )
        downloadTask.hardRefresh = true
        downloadTask.begin()
        return downloadTask
    }
    static func downloadTask(
        storageDocument: RemoteFileProtocol,
        localDocument: LocalFile,
        handler: ((DownloadTaskRoot.CompletionStatus, DownloadTaskSnapshot) -> Void)? = nil
    ) -> RemoteFileDownloadTask {
        return RemoteFileDownloadTask(remoteFile: storageDocument, handler: handler)
    }
    static func write(_ storageDocument: RemoteFileProtocol, toFile: LocalFile) -> RemoteFileDownloadTask {
        return Self.writeToLocal(storageDocument: storageDocument, localDocument: toFile)
    }
    public func writeToLocal(handler: ((DownloadTaskRoot.CompletionStatus, DownloadTaskSnapshot) -> Void)? = nil) -> RemoteFileDownloadTask {
        return Self.writeToLocal(storageDocument: self, localDocument: localFile, handler: handler)
    }
    public var downloadTask: RemoteFileDownloadTask {
        return Self.downloadTask(storageDocument: self, localDocument: localFile)
    }
    
    var downloadTask2: NewDownloadTask {
        return NewDownloadTask(remoteFile: self, hardRefresh: false)
    }
}


