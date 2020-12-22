//
//  RemoteDataLocationFirestore.swift
//  RemoteData
//
//  Created by William Piotrowski on 11/18/20.
//  Copyright © 2020 William Piotrowski. All rights reserved.
//

import FirebaseFirestore
import PromiseKit
import ReactiveSwift

// MARK: COLLECTION REF
extension RemoteDataLocation {
    var collectionReference: CollectionReference {
        return Firestore.firestore().collection(path)
    }
}

// MARK: GETALL
extension RemoteDataLocation {
    
    // SHOULD BE INTERNAL because uses Query from Firebase??
    internal static func getAll(
        query: Query,
        remoteDataLocation: RemoteDataLocation
    ) -> Promise<[ReadableRemoteData]> {
        return Promise { seal in
            query.getDocuments(){ response, queryError in
                do {
                    let readableRemoteDataArray = try remoteDataLocation.makeReadableRemoteDataFrom(
                            querySnapshot: response
                    )
                    seal.fulfill(readableRemoteDataArray)
                } catch {
                    seal.reject(queryError ?? error)
                }
            }
        }
    }
    /// Get all documents that apply to query. If one document does not initialize correctly, the entire array fails.
    static func getAll(
        remoteDataTypeFolder: RemoteDataLocation,
        filters: [WhereFilter]? = nil
    ) -> Promise<[ReadableRemoteData]> {
        //print("GET ALL 3.1")
        let collectionReference = remoteDataTypeFolder.collectionReference
        let query = Self.makeQueryFrom(
            collectionReference: collectionReference,
            filters: filters
        )
        return Self.getAll(
            query: query,
            remoteDataLocation: remoteDataTypeFolder
        )
    }
    /// Get all documents that apply to query. If one document does not initialize correctly, the entire array fails.
    public func getAll(
        filters: [WhereFilter]? = nil
    ) -> Promise<[ReadableRemoteData]> {
        return Self.getAll(
            remoteDataTypeFolder: self,
            filters: filters
        )
    }
    /*
    
    
    
    public static func getAll(
        remoteDataFolder: RemoteDataLocation
    ) -> Promise<[ReadableRemoteData]> {
        let query = remoteDataFolder.collectionReference
        return Self.getAll(
            query: query,
            remoteDataLocation: remoteDataFolder
        )
    }
    
    public static func getAllWhere(
        remoteDataFolder: RemoteDataLocation,
        field: String,
        isEqualTo: Any
    ) -> Promise<[ReadableRemoteData]> {
        let query = remoteDataFolder.collectionReference.whereField(
            field,
            isEqualTo: isEqualTo
        )
        return Self.getAll(
            query: query,
            remoteDataLocation: remoteDataFolder
        )
    }

    public func getAll() -> Promise<[ReadableRemoteData]> {
        return Self.getAll(
            remoteDataFolder: self
        )
    }
    
    public func getAllWhere(
        field: String,
        isEqualTo: Any
    ) -> Promise<[ReadableRemoteData]> {
        return Self.getAllWhere(
            remoteDataFolder: self,
            field: field,
            isEqualTo: isEqualTo
        )
    }

 */
}
// MARK: ADD LISTENER
extension RemoteDataLocation {
    //@available(*, deprecated, message: "use addListener() -> Signal")
    static func addListener(
        remoteDataFolder: RemoteDataLocation
    ) -> RemoteDataLocationListenerResponse {
        let signal = Signal<GetAllResponse, Never>.pipe()
        let disposable = remoteDataFolder.collectionReference.addSnapshotListener {
            (querySnapshot, error) in
            
            let response = GetAllResponse(
                querySnapshot: querySnapshot,
                error: error,
                serverLocation: remoteDataFolder
            )
            signal.input.send(value: response)
        }
        return (signal.output, disposable)
    }
    
    public func addListener() -> RemoteDataLocationListenerResponse {
        return Self.addListener(remoteDataFolder: self)
    }

    // MAY WANT TO CHANGE TO Signal<[GetAllResponse], Error> or Signal<[ReadableRemoteData, Error>
    public typealias RemoteDataLocationListenerResponse = (
        observer: Signal<GetAllResponse, Never>,
        disposable: ListenerDisposable
    )
}




// MARK: GENERATE ID
extension RemoteDataLocation {
    static func generateDocumentID(serverLocation: RemoteDataLocation) -> String {
        return serverLocation.collectionReference.document().documentID
    }
    
    public func generateDocumentID() -> String {
        return Self.generateDocumentID(serverLocation: self)
    }
}


// MARK: T VERSION
extension RemoteDataLocation {
    internal static func getAll<T: ReadableRemoteData>(
        query: Query,
        remoteDataLocation: RemoteDataLocation
    ) -> Promise<[T]> {
        return Promise { seal in
            query.getDocuments(){ response, queryError in
                do {
                    let readableRemoteDataArray: [T] = try remoteDataLocation.makeReadableRemoteDataArrayFrom(
                        querySnapshot: response
                    )
                    seal.fulfill(readableRemoteDataArray)
                } catch {
                    seal.reject(queryError ?? error)
                }
            }
        }
    }
    static func getAll<T: ReadableRemoteData>(
        remoteDataTypeFolder: RemoteDataLocation,
        filters: [WhereFilter]? = nil
    ) -> Promise<[T]> {
        //print("GET ALL 3.1")
        let collectionReference = remoteDataTypeFolder.collectionReference
        let query = Self.makeQueryFrom(
            collectionReference: collectionReference,
            filters: filters
        )
        return Self.getAll(
            query: query,
            remoteDataLocation: remoteDataTypeFolder
        )
    }
    public func getAll<T: ReadableRemoteData>(
        filters: [WhereFilter]? = nil
    ) -> Promise<[T]> {
        return Self.getAll(
            remoteDataTypeFolder: self,
            filters: filters
        )
    }
    
    public static func getAll<T: ReadableRemoteData>(
        remoteDataFolder: RemoteDataLocation
    ) -> Promise<[T]> {
        let query = remoteDataFolder.collectionReference
        return Self.getAll(
            query: query,
            remoteDataLocation: remoteDataFolder
        )
    }
    
    public static func getAllWhere<T: ReadableRemoteData>(
        remoteDataFolder: RemoteDataLocation,
        field: String,
        isEqualTo: Any
    ) -> Promise<[T]> {
        let query = remoteDataFolder.collectionReference.whereField(
            field,
            isEqualTo: isEqualTo
        )
        return Self.getAll(
            query: query,
            remoteDataLocation: remoteDataFolder
        )
    }

    public func getAll<T: ReadableRemoteData>() -> Promise<[T]> {
        return Self.getAll(
            remoteDataFolder: self
        )
    }
    
    public func getAllWhere<T: ReadableRemoteData>(
        field: String,
        isEqualTo: Any
    ) -> Promise<[T]> {
        return Self.getAllWhere(
            remoteDataFolder: self,
            field: field,
            isEqualTo: isEqualTo
        )
    }
}
