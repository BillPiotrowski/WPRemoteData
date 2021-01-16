//
//  RemoteDataTypeDataFirestore.swift
//  ServerData
//
//  Created by William Piotrowski on 6/16/20.
//  Copyright © 2020 William Piotrowski. All rights reserved.
//

import SPCommon
import FirebaseFirestore


// RENAME TO REMOTE DATA LOCATION?

// MARK: FOLDER PROTOCOL
/// Protocol describing a remote server location where data can be referenced.
public protocol RemoteDataLocation: RemoteDataItem {
    static var name: String { get }
    
    /// The optional parent. This would be used to generate the path. If no parent is set, collection will exist in the root directory.
    ///
    /// In the future, this could be generic, but not sure that is necessary. Would allow to traverse database more, but seems unnessary.
    var parentReference: RemoteDataReference? { get }
    
    // This should be removed at some point
//    func makeRemoteDataReference(
//        document: RemoteDataDocument
//    ) -> RemoteDataReference
    
    static var database: DatabaseInterface { get }
}

// MARK: DEFAULT
extension RemoteDataLocation {
    public var parentReference: RemoteDataReference? { nil }
}




// MARK: COMFORM: RemoteDataItem
extension RemoteDataLocation {
    public var name: String {
        Self.name
    }
    public var parentPathArray: [String] {
        parentReference?.pathArray ?? []
    }
}





























































/*
extension RemoteDataLocation {
    // THROWS IF THERE IS A SINGLE ERROR IN DOCS
    /// Converts the response from a Cloud Firestore QuerySnapshot into and array of ReadableRemoteData. Throws error if there is a problem with any single file.
    private static func makeReadableRemoteDataFrom(
        remoteDataTypeFolder: Self,
        document: RemoteDataDocument
    ) throws -> ReadableRemoteData {
           
        let remoteDataType = remoteDataTypeFolder.makeRemoteDataReference(
            document: document
        )
        return try remoteDataType.readableRemoteDataType(remoteDataDocument: document).init(
            remoteDataDocument: document
        )
    }
    
    /// Converts the response from a Cloud Firestore QuerySnapshot into and array of ReadableRemoteData. Throws error if there is a problem with any single file.
    public func makeReadableRemoteDataFrom(
        document: RemoteDataDocument
    ) throws -> ReadableRemoteData {
        return try Self.makeReadableRemoteDataFrom(
            remoteDataTypeFolder: self,
            document: document
        )
    }
    
    public func makeReadableRemoteDataFrom<T: ReadableRemoteData>(
        document: RemoteDataDocument
    ) throws -> T {
        return try T(remoteDataDocument: document)
    }
}
*/
