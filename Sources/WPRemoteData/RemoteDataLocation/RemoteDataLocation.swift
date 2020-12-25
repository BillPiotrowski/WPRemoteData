//
//  RemoteDataTypeDataFirestore.swift
//  ServerData
//
//  Created by William Piotrowski on 6/16/20.
//  Copyright © 2020 William Piotrowski. All rights reserved.
//

import SPCommon
import SPCommon


// RENAME TO REMOTE DATA LOCATION?

// MARK: FOLDER PROTOCOL
/// Protocol describing a remote server location where data can be referenced.
public protocol RemoteDataLocation: RemoteCommonProtocol {
    var relativePathArray: [String] { get }
    var parentLocation: RemoteDataLocation? { get }
    func makeRemoteDataReference(
        document: RemoteDataDocument
    ) -> RemoteDataReference
}

extension RemoteDataLocation {
    public var pathArray: [String] {
        var pathArray = parentPathArray
        pathArray.append(contentsOf: relativePathArray)
        return pathArray
    }
    
    internal var path: String {
        return pathArray.joined(separator: "/")
    }
    
    internal var parentPathArray: [String] {
        return parentLocation?.pathArray ?? []
    }
}



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
