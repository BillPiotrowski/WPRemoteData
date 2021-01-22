//
//  RemoteFile.swift
//  RemoteFile
//
//  Created by William Piotrowski on 6/28/20.
//  Copyright © 2020 William Piotrowski. All rights reserved.
//

import Foundation
import SPCommon
import ReactiveSwift
import Promises




// IS THIS NECESSARY???
public protocol RemoteFileProtocol: RemoteDataItem {
    var location: RemoteFileFolderProtocol { get }
    var name: String { get }
    
    /// REMOVE THIS AND RELY ON RemoteFile (Remote file downloadable)
    var localFile: LocalFile { get }
}

// MARK: - CONFORM: RemoteDataItem
extension RemoteFileProtocol {
    public var parentPathArray: [String] {
        return location.pathArray
    }
}



public protocol RemoteFile: RemoteFileProtocol {
    associatedtype LocalDoc: LocalFile
    var localDoc: LocalDoc { get }
}
extension RemoteFile {
    public var localFile: LocalFile {
        self.localDoc
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
}
extension RemoteFileProtocol {
    
    public var isLocal: Bool {
        return localFile.exists
    }
}













extension RemoteFileProtocol /*: RemoteDownloadable*/ {
    // SHOULD NOT BE PUBLIC!
    internal var ref: StorageReferenceInterface {
        return location.locationInterface.childInterface(name)
    }
    internal var downloadTask2: RemoteFileDownloadTask {
        return RemoteFileDownloadTask(
            remoteFile: self,
            hardRefresh: false
        )
    }
    public func createDownloadTask(
        hardRefresh: Bool? = nil
    ) -> RemoteFileDownloadTask {
        let hardRefresh = hardRefresh ?? false
        return RemoteFileDownloadTask(
            remoteFile: self,
            hardRefresh: hardRefresh
        )
    }
    
    ///
    /// - Parameter hardRefresh: If hard refresh is set to true, method will always load from remote.
    /// - Returns: Returns a Promise containing the local url of a document if and when it exists on the device. Will not return the URL if the file does not exist or download was unsuccessful.
    public func getURL(
        hardRefresh: Bool? = nil
    ) -> Promise<URL> {
        if
            hardRefresh == true,
            localFile.exists
        {
            return Promise<URL>.init(localFile.url)
        }
        return getFromRemote()
    }
    
    /// Downloads file and returns the local URL.
    internal func getFromRemote() -> Promise<URL> {
        return Promise { fulfill, reject in
            let task = self.downloadTask2
            task.progressSignal.observe(
                Signal<Double, Error>.Observer(
                    failed: {error in
                        reject(error)
                    },
                    completed: {
                        fulfill(self.localFile.url)
                    },
                    interrupted: {
                        reject(DownloadError.downloadInterrupted)
                    }
                )
            )
            _ = task.start()
        }
    }
}



extension RemoteFile where
    LocalDoc: LocalFileOpenable
{
    
    /// Get will attempt to get file from local device, but if it is not local, download from remote.
    /// - Parameter hardRefresh: If hard refresh is true, it will always download from remote.
    /// - Returns: A Promise containing the contents of the OpenableFile. There is no timeout on this unless Firebase has one baked in.
    ///
    /// - todo: Determine how to handle if no service.
    public func get(
        hardRefresh: Bool? = nil
    ) -> Promise<LocalDoc.O>{
        if
            hardRefresh == true,
            let content = try? self.localDoc.contents()
        {
            return Promise<LocalDoc.O>(content)
        }
        return self.getContentsFromRemote()
    }
    
    internal func getContentsFromRemote() -> Promise<LocalDoc.O>{
        self.getFromRemote()
        .then { _ -> LocalDoc.O in
            return try localDoc.contents()
        }
    }
    
}




private enum DownloadError: ScorepioError {
    case downloadInterrupted
    
    var message: String {
        switch self {
        case .downloadInterrupted: return "Download was unexpectedly interrupted."
        }
    }
}
