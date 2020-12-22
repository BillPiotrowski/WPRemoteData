//
//  RemoteDataLocationHelper.swift
//  RemoteData
//
//  Created by William Piotrowski on 11/18/20.
//  Copyright © 2020 William Piotrowski. All rights reserved.
//

import FirebaseFirestore

// MARK: HELPER METHODS
extension RemoteDataLocation {
    
    // THROWS IF THERE IS A SINGLE ERROR IN DOCS
    /// Converts the response from a Cloud Firestore QuerySnapshot into and array of ReadableRemoteData. Throws error if there is a problem with any single file.
    internal static func makeReadableRemoteDataFrom(
        remoteDataTypeFolder: RemoteDataLocation,
        querySnapshot: QuerySnapshot?
    ) throws -> [ReadableRemoteData] {
        var readableRemoteData = [ReadableRemoteData]()
        guard let querySnapshot = querySnapshot
            else { throw RemoteDataLocationError.missingQuerySnapshot }
        for document in querySnapshot.documents {
            let dictionary = RemoteDataDocument(
                document: document,
                folder: remoteDataTypeFolder
            )
            let readableData = try remoteDataTypeFolder.makeReadableRemoteDataFrom(
                document: dictionary
            )
            readableRemoteData.append(readableData)
        }
        return readableRemoteData
    }
    
    internal static func makeReadableRemoteDataFrom<T: ReadableRemoteData>(
        remoteDataTypeFolder: RemoteDataLocation,
        querySnapshot: QuerySnapshot?
    ) throws -> [T] {
        var readableRemoteDataArray = [T]()
        guard let querySnapshot = querySnapshot
            else { throw RemoteDataLocationError.missingQuerySnapshot }
        for document in querySnapshot.documents {
            let dictionary = RemoteDataDocument(
                document: document,
                folder: remoteDataTypeFolder
            )
            let readableRemoteData = try T(remoteDataDocument: dictionary)
            readableRemoteDataArray.append(readableRemoteData)
        }
        return readableRemoteDataArray
    }
    
    /// Converts the response from a Cloud Firestore QuerySnapshot into and array of ReadableRemoteData. Throws error if there is a problem with any single file.
    internal func makeReadableRemoteDataFrom(
        querySnapshot: QuerySnapshot?
    ) throws -> [ReadableRemoteData] {
        return try Self.makeReadableRemoteDataFrom(
            remoteDataTypeFolder: self,
            querySnapshot: querySnapshot
        )
    }
    internal func makeReadableRemoteDataArrayFrom<T: ReadableRemoteData>(
        querySnapshot: QuerySnapshot?
    ) throws -> [T] {
        return try Self.makeReadableRemoteDataFrom(
            remoteDataTypeFolder: self,
            querySnapshot: querySnapshot
        )
    }
    
    /// Creates a usable Cloud Firestore Query from a CollectionReference and filters
    internal static func makeQueryFrom(
        collectionReference: CollectionReference,
        filters: [WhereFilter]? = nil
    ) -> Query {
        var query: Query = collectionReference
        if let filters = filters {
            for filter in filters {
                query = filter.applyTo(query: query)
            }
        }
        return query
    }
}
