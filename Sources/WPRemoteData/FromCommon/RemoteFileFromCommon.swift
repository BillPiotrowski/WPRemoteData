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
public protocol RemoteFileProtocol: RemoteDownloadable {
    var location: RemoteFileFolderProtocol { get }
    var name: String { get }
    var localFile: LocalFileReference { get }
    init(remoteFileFolder: RemoteFileFolderProtocol, file: String) throws
    
    
    
    
    
    
    
    
    /*
    public var ref: StorageReference {
        return location.location.child(name)
    }
 */
    //var downloadTaskProtocol: DownloadTaskProtocol { get }
    /*
    static func writeToLocal(
        storageDocument: RemoteFileProtocol,
        localDocument: LocalFileProtocol,
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
        localDocument: LocalFileProtocol,
        handler: ((DownloadTaskRoot.CompletionStatus, DownloadTaskSnapshot) -> Void)? = nil
    ) -> RemoteFileDownloadTask {
        return RemoteFileDownloadTask(remoteFile: storageDocument, handler: handler)
    }
    static func write(_ storageDocument: RemoteFileProtocol, toFile: LocalFileProtocol) -> RemoteFileDownloadTask {
        return Self.writeToLocal(storageDocument: storageDocument, localDocument: toFile)
    }
    */
    /*
    func writeToLocal(handler: ((DownloadTaskRoot.CompletionStatus, DownloadTaskSnapshot) -> Void)?) -> DownloadTaskRoot
    var downloadTask: DownloadTaskRoot  { get }
    */
    
    
    
    
}
/*
extension RemoteFileProtocol {
    // SHOULD NOT BE PUBLIC!
    public var ref: StorageReference {
        return location.location.child(name)
    }
}
*/

public protocol RemoteDownloadable {
    var downloadTaskProtocol: DownloadTaskProtocol { get }
}

extension RemoteFileProtocol {
    
    public var isLocal: Bool {
        return localFile.exists
    }
}









/*
extension RemoteFileProtocol /*: RemoteDownloadable*/ {
    // SHOULD NOT BE PUBLIC!
    public var ref: StorageReference {
        return location.location.child(name)
    }
    public var downloadTaskProtocol: DownloadTaskProtocol {
        return downloadTask
    }
    static func writeToLocal(
        storageDocument: RemoteFileProtocol,
        localDocument: LocalFileProtocol,
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
        localDocument: LocalFileProtocol,
        handler: ((DownloadTaskRoot.CompletionStatus, DownloadTaskSnapshot) -> Void)? = nil
    ) -> RemoteFileDownloadTask {
        return RemoteFileDownloadTask(remoteFile: storageDocument, handler: handler)
    }
    static func write(_ storageDocument: RemoteFileProtocol, toFile: LocalFileProtocol) -> RemoteFileDownloadTask {
        return Self.writeToLocal(storageDocument: storageDocument, localDocument: toFile)
    }
    public func writeToLocal(handler: ((DownloadTaskRoot.CompletionStatus, DownloadTaskSnapshot) -> Void)? = nil) -> RemoteFileDownloadTask {
        return Self.writeToLocal(storageDocument: self, localDocument: localFile, handler: handler)
    }
    public var downloadTask: RemoteFileDownloadTask {
        return Self.downloadTask(storageDocument: self, localDocument: localFile)
    }
}


*/
