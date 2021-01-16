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
import Promises

// MARK: COLLECTION REF
extension RemoteDataLocation {
    /// Complete relative path (including name), separated by "/".
    ///
    /// Used to create Firebase `CollectionReference`.
    internal var path: String {
        return pathArray.joined(separator: "/")
    }
    
    /// The Firebase reference to the collection.
    ///
    /// Used to define the folder location.
    var collectionReferenceInterface: CollectionReferenceInterface {
        return Self.database.collectionInterface(path)
    }
    var collectionReference: CollectionReferenceInterface {
        self.collectionReferenceInterface
//        return database.collection(path)
    }
}
// MARK: DEFAULT
extension RemoteDataLocation {
    public static var database: DatabaseInterface { Firestore.firestore() }
}


// MARK: GENERATE ID
extension RemoteDataLocation {
    
    /// Generates a unique ID for the location without the need to send a server request.
    public func generateDocumentID() -> String {
        return collectionReferenceInterface.documentInterface().documentID
    }
}




// MARK: GETALL
extension RemoteDataLocation {
    
//    @available(*, deprecated, message: "Use new database model.")
//    /// Get all documents that apply to query. If one document does not initialize correctly, the entire array fails.
//    public func getAllDocs(
//        filters: [WhereFilter]? = nil
//    ) -> Promises.Promise<[RemoteDataDocument]> {
//        let query: QueryInterface = self.collectionReference.getQuery(
//            from: filters
//        )
//        return query.getAll().then {
//            return $0.documentsInterface.map {
//                doc -> RemoteDataDocument in
//                return RemoteDataDocument(
//                    document: doc,
//                    folder: self
//                )
//            }
//        }
//    }
    
//    @available(*, deprecated, message: "Use new database model.")
//    /// Gets all document data.
//    public func getAllData(
//        filters: [WhereFilter]? = nil
//    ) -> Promises.Promise<[ReadableRemoteData]> {
//        return self.getAllDocs(filters: filters).then {
//            return try $0.map{ doc -> ReadableRemoteData in
//                try self.makeReadableRemoteDataFrom(document: doc)
//            }
//        }
//    }
}

// MARK: -
// MARK: ADD LISTENER
extension RemoteDataLocation {
    //@available(*, deprecated, message: "use addListener() -> Signal")
//    static func addListener(
//        remoteDataFolder: RemoteDataLocation
//    ) -> RemoteDataLocationListenerResponse {
//        let signal = Signal<GetAllResponse, Never>.pipe()
//        let disposable = remoteDataFolder.collectionReference.addSnapshotListenerInterface {
//            (querySnapshot, error) in
//            
//            let response = GetAllResponse(
//                querySnapshot: querySnapshot,
//                error: error,
//                serverLocation: remoteDataFolder
//            )
//            signal.input.send(value: response)
//        }
//        return (signal.output, disposable)
//    }
    
//    public func addListener() -> RemoteDataLocationListenerResponse {
//        return Self.addListener(remoteDataFolder: self)
//    }
//
//    // MAY WANT TO CHANGE TO Signal<[GetAllResponse], Error> or Signal<[ReadableRemoteData, Error>
//    public typealias RemoteDataLocationListenerResponse = (
//        observer: Signal<GetAllResponse, Never>,
//        disposable: ListenerDisposable
//    )
}





// MARK: -
// MARK: T VERSION
// This should all be removed eventually and replaced with new database model.
/*
@available(*, deprecated, message: "Use new database model.")
extension RemoteDataLocation {
    internal static func getAll<T: ReadableRemoteData>(
        query: QueryInterface,
        remoteDataLocation: RemoteDataLocation
    ) -> PromiseKit.Promise<[T]> {
        return Promise { seal in
            query.getDocumentsInterface(){ response, queryError in
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
    
    @available(*, deprecated, message: "Use new database model.")
    static func getAll<T: ReadableRemoteData>(
        remoteDataTypeFolder: RemoteDataLocation,
        filters: [WhereFilter]? = nil
    ) -> PromiseKit.Promise<[T]> {
        let query: QueryInterface = remoteDataTypeFolder.collectionReference.getQuery(
            from: filters
        )
        return Self.getAll(
            query: query,
            remoteDataLocation: remoteDataTypeFolder
        )
    }
    
    @available(*, deprecated, message: "Use new database model.")
    public func getAll<T: ReadableRemoteData>(
        filters: [WhereFilter]? = nil
    ) -> PromiseKit.Promise<[T]> {
        return Self.getAll(
            remoteDataTypeFolder: self,
            filters: filters
        )
    }
    
    @available(*, deprecated, message: "Use new database model.")
    public static func getAll<T: ReadableRemoteData>(
        remoteDataFolder: RemoteDataLocation
    ) -> PromiseKit.Promise<[T]> {
        let query = remoteDataFolder.collectionReference
        return Self.getAll(
            query: query,
            remoteDataLocation: remoteDataFolder
        )
    }
    
    @available(*, deprecated, message: "Use new database model.")
    public static func getAllWhere<T: ReadableRemoteData>(
        remoteDataFolder: RemoteDataLocation,
        field: String,
        isEqualTo: Any
    ) -> PromiseKit.Promise<[T]> {
        let query = remoteDataFolder.collectionReference.whereFieldInterface(
            [field],
            isEqualTo: isEqualTo
        )
        return Self.getAll(
            query: query,
            remoteDataLocation: remoteDataFolder
        )
    }

    @available(*, deprecated, message: "Use new database model.")
    public func getAll<T: ReadableRemoteData>() -> PromiseKit.Promise<[T]> {
        return Self.getAll(
            remoteDataFolder: self
        )
    }
    
    @available(*, deprecated, message: "Use new database model.")
    public func getAllWhere<T: ReadableRemoteData>(
        field: String,
        isEqualTo: Any
    ) -> PromiseKit.Promise<[T]> {
        return Self.getAllWhere(
            remoteDataFolder: self,
            field: field,
            isEqualTo: isEqualTo
        )
    }
}
*/
