//
//  RemoteDataFirestore.swift
//  RemoteData
//
//  Created by William Piotrowski on 11/18/20.
//  Copyright © 2020 William Piotrowski. All rights reserved.
//

import FirebaseFirestore
import PromiseKit
import ReactiveSwift

extension RemoteDataReference {
    var documentReference: DocumentReference {
        return remoteDataLocation.collectionReference.document(documentID)
    }
}

// MARK: GET PROMISE
extension RemoteDataReference {
    static func get (
        initializableData: RemoteDataReference
    ) -> Promise<ReadableRemoteData> {
        return Promise { seal in
            initializableData.documentReference.getDocument {
                documentSnapshot, getError in

                do {

                    guard let documentSnapshot = documentSnapshot
                        else { throw RemoteDataReferenceError.documentDoesNotExist(
                            serverDocument: initializableData
                        )
                    }
                    let document = RemoteDataDocument(
                        document: documentSnapshot,
                        folder: initializableData.remoteDataLocation
                    )
                    let readableRemoteData = try document.makeReadableRemoteData()
                    
                    seal.fulfill(readableRemoteData)
                } catch {
                    seal.reject(getError ?? error)
                }
            }
        }
    }
    
    public func get() -> Promise <ReadableRemoteData> {
        return Self.get(initializableData: self)
    }
}

// MARK: ADD LISTENER
// BETTER TO KEEP THIS WITH CALLBACK SO THERE ARENT PERMANENT PROMISES?


public enum ServerListenerResponse<T: ListenableRemoteData>{
    case error(error: Error)
    case success(response: T)
}

extension RemoteDataReference {
    
    static func addListenerNoError<T: ListenableRemoteData>(
        remoteDataProtocol: RemoteDataReference,
        type: T.Type
    ) -> (
        disposable: ListenerDisposable,
        observer: Signal<ServerListenerResponse<T>, Never>
    ) {
        let signal = Signal<ServerListenerResponse<T>, Never>.pipe()
        let disposable = remoteDataProtocol.documentReference.addSnapshotListener { documentSnapshot, error in
            
            guard let documentSnapshot = documentSnapshot
                else {
                    let error = error ?? RemoteDataReferenceError.documentDoesNotExist(
                        serverDocument: remoteDataProtocol
                    )
                    signal.input.send(value: .error(error: error))
                    return
            }
            
            let serverDoc = RemoteDataDocument(
                document: documentSnapshot,
                folder: remoteDataProtocol.remoteDataLocation
            )
            
            do {
                let data = try T(remoteDataDocument: serverDoc)
                signal.input.send(value: .success(response: data))
            } catch {
                signal.input.send(value: .error(error: error))
            }
        }
        return (disposable, signal.output)
    }
    func addListenerNoError<T: ListenableRemoteData>(type: T.Type) -> (
        disposable: ListenerDisposable,
        observer: Signal<ServerListenerResponse<T>, Never>
    ) {
        return Self.addListenerNoError(
            remoteDataProtocol: self,
            type: type
        )
    }
    
    
    
    
    
    
    // NEED TO TEST. MAKE SURE THAT IT IS HELD ON TO.
    static func addListener<T: ListenableRemoteData>(
        remoteDataProtocol: RemoteDataReference,
        type: T.Type
    ) -> (
        disposable: ListenerDisposable,
        observer: Signal<T, Error>
    ) {
        let signal = Signal<T, Error>.pipe()
        let disposable = remoteDataProtocol.documentReference.addSnapshotListener { documentSnapshot, error in
            
            guard let documentSnapshot = documentSnapshot
                else {
                    signal.input.send(
                        error: RemoteDataReferenceError.documentDoesNotExist(
                            serverDocument: remoteDataProtocol
                        )
                    )
                    return
            }
            
            let serverDoc = RemoteDataDocument(
                document: documentSnapshot,
                folder: remoteDataProtocol.remoteDataLocation
            )
            
            do {
                let data = try T(remoteDataDocument: serverDoc)
                signal.input.send(value: data)
            } catch {
                signal.input.send(error: error)
            }
        }
        return (disposable, signal.output)
    }
    
    func addListener<T: ListenableRemoteData>(type: T.Type) -> (
        disposable: ListenerDisposable,
        observer: Signal<T, Error>
    ) {
        return Self.addListener(remoteDataProtocol: self, type: type)
    }
    
    public typealias RemoteDataReferenceListener = (
        disposable: ListenerDisposable,
        observer: Signal<ListenableRemoteData, Error>
    )
}


// MARK: TIMESTAMP CONVERT
extension RemoteDataReference {
    static func convert(rawTime: Any) -> Date? {
        guard let timestamp = rawTime as? Timestamp else { return nil }
        return timestamp.dateValue()
    }
    static func convert(date: Date) -> Timestamp {
        return Timestamp(date: date)
    }
}

// MARK: SAVE PROMISE
extension RemoteDataReference {
    // COULD BE A BETTER REPONSE TYPE??
    // RESPONDS WITH WRITE TIME?
    public static func save(
        remoteDataType: RemoteDataReference,
        dictionary: [String: Any]
    ) -> Promise<Void> {
        return Promise { seal in
            remoteDataType.documentReference.setData(dictionary){
                error in
                if let error = error {
                    seal.reject(error)
                }
                seal.fulfill(())
                // PUT IN CHECK FOR FAILURE??? IS CANCELLED?
            }
        }
    }
    public func save(dictionary: [String:Any]) -> Promise<Void>{
        return Self.save(
            remoteDataType: self,
            dictionary: dictionary
        )
    }
}
