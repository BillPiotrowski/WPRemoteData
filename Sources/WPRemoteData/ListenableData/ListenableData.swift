//
//  ListenableData.swift
//  RemoteData
//
//  Created by William Piotrowski on 12/7/20.
//  Copyright © 2020 William Piotrowski. All rights reserved.
//

import ReactiveSwift
import Firebase


public protocol ListenableRemoteData: ReadableRemoteData, WriteableRemoteData, Equatable {
    
}

// MARK: LISTENER
extension ListenableRemoteData {
    /*
    public static func remoteAddListenerNoError(
        remoteDataReference: RemoteDataReference
    ) -> RemoteDataListenerNoError {
        return remoteDataReference.addListenerNoError(
            type: Self.self
        )
    }
    public func remoteAddListenerNoError() -> RemoteDataListenerNoError {
        return Self.remoteAddListenerNoError(
            remoteDataReference: remoteDataReference
        )
    }
     */
    public typealias RemoteDataListenerNoError = (
        disposable: ListenerDisposable,
        observer: Signal<ServerListenerResponse<Self>, Never>
    )
    
    
    
    
    
    /*
    public static func remoteAddListener(
        remoteDataReference: RemoteDataReference
    ) -> RemoteDataListener {
        let signal = Signal<Self, Error>.pipe()
        let temp = remoteDataReference.addListener(type: Self.self)
        temp.observer.observe(
            Signal<Self, Error>.Observer(
                value: { (readableRemoteData) in
                    do {
                        let selfDoc = try Self.asSelf(
                            value: readableRemoteData
                        )
                        signal.input.send(value: selfDoc)
                    } catch {
                        signal.input.send(error: error)
                    }
                }, failed: {error in
                    signal.input.send(error: error)
                }//,
                //completed: {},
                //interrupted: {}
            )
        )
        return (signal.output, temp.disposable)
    }
    
    public func remoteAddListener() -> RemoteDataListener {
        return Self.remoteAddListener(
            remoteDataReference: remoteDataReference
        )
    }
     */
    
    /// Returns a Signal and ListenerDisposable. The disposable is for the server listener and is different from ReactiveSwift Disposables.
    public typealias RemoteDataListener = (
        observer: Signal<Self, Error>,
        disposable: ListenerDisposable
    )
}


/*
extension ListenableRemoteData {
    internal func makeListenableRemoteData() throws -> Self {
        guard let listenableRemoteData = self as? Self
            else {
                throw NSError(domain: "could not convert to ListenableRemoteData", code: 34, userInfo: nil)
        }
        return listenableRemoteData
        
        // Alternative:
        /*
        return try remoteDataReference.readableRemoteDataType.init(
            dictionary: dictionary,
            serverDocument: remoteDataReference
        )
        */
    }
}
*/
