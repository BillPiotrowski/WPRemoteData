//
//  LocallyArchivableRemoteDataReference.swift
//  RemoteData
//
//  Created by William Piotrowski on 11/15/20.
//  Copyright © 2020 William Piotrowski. All rights reserved.
//

import PromiseKit
import SPCommon
import Promises
import Foundation
import ReactiveSwift


public protocol LocallyArchivableRemoteDataReference: RemoteDataReference, RemoteDownloadable {
    var localFileReference: LocalFileOpenableRedundant { get }
}


// MARK: - DOWNLOADABLE
public protocol RemoteDataDownloadableDoc: RemoteDataReferenceGeneric, LocallyArchivableRemoteDataReference {
    associatedtype LocalDoc: LocalFileOpenable
    
    var localDoc: LocalDoc { get }
    
}



// SIMPLIFY??
extension RemoteDataReferenceGeneric where
    Self: RemoteDataDownloadableDoc,
    Self.Data == Self.LocalDoc.O,
    Self.Data.Reference == Self,
    Self.LocalDoc == Self.LocalDoc.O.File,
    LocalDoc.O: LocalOpenableData
{
    public func download(
    ) -> Promises.Promise<Self.Data> {
        return self.get()
        .then { response -> Self.Data in
            try localDoc.archive(dictionary: response.data.dictionary)
            return response.data
        }
    }
    
    private var downloadSignal: Signal<Double, Error> {
        let signal = Signal<Double, Error>.pipe()
        self.download().then{ response in
            signal.input.send(value: 1)
            signal.input.sendCompleted()
        }.catch{ error in
            signal.input.send(error: error)
        }
        return signal.output
    }
    
    public var downloadAction: Action<Void, Double, Error> {
        return Action { (_) -> SignalProducer<Double, Error> in
            return self.downloadSignal.producer
        }
    }
    
    public var downloadTask: DownloadTaskProtocol {
        RemoteDataDownloadTask(action: self.downloadAction, localURL: localDoc.url)
    }
    /// Unnecessary conformance to RemoteDownloadable.
    ///
    /// Would like to remove this in future.
    public var downloadTaskProtocol: DownloadTaskProtocol { self.downloadTask }
    
    
    
//    public var downloadTask: DownloadTaskProtocol {
//        return Self.downloadTask(remoteData: self)
//    }
//    static func downloadTask(remoteData: LocallyArchivableRemoteDataReference) -> RemoteDataDownloadTask {
//        return RemoteDataDownloadTask(remoteDataProtocol: remoteData)
//    }
}



/*
// MARK: DOWNLOAD PROMISE
extension LocallyArchivableRemoteDataReference {
    /// Gets data, saves it locally and returns it. Will fail if local write fails.
    public static func download(
        remoteDataType: LocallyArchivableRemoteDataReference
    ) -> PromiseKit.Promise<ReadableRemoteData> {
    
        return Self.get(initializableData: remoteDataType)

            .then { readableRemoteData -> PromiseKit.Promise<ReadableRemoteData> in
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
    public func download() -> PromiseKit.Promise<ReadableRemoteData> {
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

*/
