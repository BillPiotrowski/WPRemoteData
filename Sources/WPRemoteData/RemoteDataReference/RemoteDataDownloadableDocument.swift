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



// MARK: - DOWNLOADABLE
/// Protocol describing a GettableRemoteDataDocument that can be downloaded to the local device.
///
/// Downloading methods currently do not return the Generic type, but will save to local.
public protocol RemoteDataDownloadableDocument: GettableRemoteDataDocument {
    associatedtype LocalDoc: LocalFileOpenable
    
    var localDocument: LocalDoc { get }
    
}



// SIMPLIFY??
extension RemoteDataDownloadableDocument where
    Self.Data == Self.LocalDoc.O,
    Self.Data.RemoteDoc == Self,
    Self.LocalDoc == Self.LocalDoc.O.File,
    LocalDoc.O: LocalOpenableData
{
    public func download(
    ) -> Promises.Promise<Self.Data> {
        return self.get()
        .then { response -> Self.Data in
            try localDocument.archive(dictionary: response.data.dictionary)
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
    
    public var downloadTask: RemoteDataDownloadTask<Self> {
        RemoteDataDownloadTask(
            remoteDataDocument: self
        )
    }
    /// Unnecessary conformance to RemoteDownloadable.
    ///
    /// Would like to remove this in future.
    public var downloadTaskProtocol: NewDownloadTaskProtocol {
        self.downloadTask
    }
    
    
}


