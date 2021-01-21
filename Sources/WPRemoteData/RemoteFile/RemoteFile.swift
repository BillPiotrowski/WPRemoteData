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
public protocol RemoteFileProtocol: RemoteDataItem, RemoteDownloadable {
    var location: RemoteFileFolderProtocol { get }
    var name: String { get }
    var localFile: LocalFile { get }
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
    public var downloadTask2: RemoteFileDownloadTask {
        return RemoteFileDownloadTask(remoteFile: self, hardRefresh: false)
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
    
    /// Downloads file and returns the local URL.
    public func getFromRemote() -> Promise<URL> {
        return Promise { fulfill, reject in
            let task = self.downloadTask2
            task.progressSignal.observe(
                Signal<Double, Error>.Observer(
//                    value: {val in},
                    failed: {error in
                        reject(error)
                    },
                    completed: {
                        fulfill(self.localFile.url)
                    }//,
//                    interrupted: {}
                )
            )
            _ = task.start()
        }
    }
}


