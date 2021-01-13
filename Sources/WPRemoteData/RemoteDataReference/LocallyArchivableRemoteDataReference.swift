//
//  LocallyArchivableRemoteDataReference.swift
//  RemoteData
//
//  Created by William Piotrowski on 11/15/20.
//  Copyright © 2020 William Piotrowski. All rights reserved.
//

import PromiseKit
import SPCommon


public protocol LocallyArchivableRemoteDataReference: RemoteDataReference, RemoteDownloadable {
    var localFileReference: LocalFileOpenableRedundant { get }
}

// MARK: DOWNLOAD PROMISE
extension LocallyArchivableRemoteDataReference {
    /// Gets data, saves it locally and returns it. Will fail if local write fails.
    public static func download(
        remoteDataType: LocallyArchivableRemoteDataReference
    ) -> Promise<ReadableRemoteData> {
    
        return Self.get(initializableData: remoteDataType)

        .then { readableRemoteData -> Promise<ReadableRemoteData> in
            return Promise { seal in
                do {
                    try remoteDataType.localFileReference.archive(
                        dictionary: readableRemoteData.dictionary
                    )
                    seal.fulfill(readableRemoteData)
                } catch {
                    seal.reject(error)
                }
            }
        }
    }
    /// Gets data, saves it locally and returns it. Will fail if local write fails.
    public func download() -> Promise<ReadableRemoteData> {
        return Self.download(remoteDataType: self)
    }
}

// MARK: REMOTE DOWNLOADABLE
extension LocallyArchivableRemoteDataReference {
    public var downloadTaskProtocol: DownloadTaskProtocol {
        return downloadTask
    }
}
// MARK: DOWNLOAD TASKS
extension LocallyArchivableRemoteDataReference {
    static func downloadTask(remoteData: LocallyArchivableRemoteDataReference) -> RemoteDataDownloadTask {
        return RemoteDataDownloadTask(remoteDataProtocol: remoteData)
    }
    public var downloadTask: DownloadTaskProtocol {
        return Self.downloadTask(remoteData: self)
    }
}
