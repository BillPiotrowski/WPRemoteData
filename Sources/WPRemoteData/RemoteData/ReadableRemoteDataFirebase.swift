//
//  ReadableRemoteDataFirestore.swift
//  RemoteData
//
//  Created by William Piotrowski on 11/18/20.
//  Copyright © 2020 William Piotrowski. All rights reserved.
//

import PromiseKit
import ReactiveSwift
import Firebase
import Promises

// MARK: GET PROMISE
//extension ReadableRemoteData {
//    public static func remoteGet(
//        serverDocument: RemoteDataReference
//    ) -> PromiseKit.Promise<Self> {
//        return Promise { seal in
//            serverDocument.get()
//            .done{ readableRemoteData in
//                do {
//                    //let selfData = try readableRemoteData.asSelf()
//                    let selfData = try Self.asSelf(
//                        value: readableRemoteData
//                    )
//                    seal.fulfill(selfData)
//                } catch {
//                    seal.reject(error)
//                }
//            }.catch{ error in
//                seal.reject(error)
//            }
//        }
//    }
//    // CANT SEEM TO USE STATIC AND MAINTAINT Self. Still relevant?
//    public func remoteGet() -> PromiseKit.Promise<Self> {
//        return Self.remoteGet(serverDocument: self.remoteDataReference)
//    }
//}
 


// MARK: FOLDER ADD LISTENER
extension ReadableRemoteData {
//    public static func remoteAddFolderListener(
//        folder: RemoteDataLocation
//    ) -> RemoteDataFolderListener {
//        let signal = Signal<[Self], Error>.pipe()
//        let temp = folder.addListener()
//        temp.observer.observe(Signal<GetAllResponse, Never>.Observer(value: { (response) in
//            if let error = response.error {
//                signal.input.send(error: error)
//            }
//            do {
//                var selfArray = [Self]()
//                for doc in response.documents {
//                    let selfDoc = try Self.asSelf(value: doc)
//                    selfArray.append(selfDoc)
//                }
//                signal.input.send(value: selfArray)
//            } catch {
//                signal.input.send(error: error)
//            }
//        }))
//        
//        return (signal.output, temp.disposable)
//    }
    
    public typealias RemoteDataFolderListener = (
        observer: Signal<[Self], Error>,
        disposable: ListenerDisposable
    )
    
}


// MARK: GETALL PROMISE
/// Returns Get All as Self
//extension ReadableRemoteData {
//    public static func remoteGetAll(
//        serverLocation: RemoteDataLocation,
//        filters: [WhereFilter]? = nil
//    ) -> Promises.Promise<[Self]> {
//        return serverLocation.getAllData(
//            filters: filters
//        ).then { remoteDataArray in
//            return try remoteDataArray.map {
//                return try Self.asSelf(value: $0)
//            }
//        }
//    }
//}
