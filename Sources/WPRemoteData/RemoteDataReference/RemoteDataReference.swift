//
//  RemoteDataTypeProtocol.swift
//  ServerData
//
//  Created by William Piotrowski on 6/16/20.
//  Copyright © 2020 William Piotrowski. All rights reserved.
//

import SPCommon

public protocol RemoteDataReferenceKnownType: RemoteDataReference {
    var readableRemoteDataType: ReadableRemoteData.Type { get }
}
extension RemoteDataReferenceKnownType {
    public func readableRemoteDataType(
        remoteDataDocument: RemoteDataDocument
    ) -> ReadableRemoteData.Type {
        return readableRemoteDataType
    }
}










/// Protocol describing a reference to data that exists on a remote server.
public protocol RemoteDataReference: RemoteDataItem {
    
    /// The identifier for the document.
    ///
    /// For consistenty with Local, might change this to `name`.
    var documentID: String { get }
    
    var remoteDataLocation: RemoteDataLocation { get }
    
    
    func readableRemoteDataType(
        remoteDataDocument: RemoteDataDocument
    ) -> ReadableRemoteData.Type
    
}

// MARK: -
// MARK: CONFORM: RemoteDataItem
extension RemoteDataReference {
    public var parentPathArray: [String] {
        remoteDataLocation.pathArray
    }
    public var name: String { documentID }
}










extension RemoteDataReference {
    /*
    // DEPRECATE AND SIMPLY USE readableRemoteDataType.init()
    private static func makeReadableRemoteDataFrom<T: ReadableRemoteData>(
        remoteDataDocument: RemoteDataDocument
        /*
        remoteDataType: Self,
        dictionary: [String: Any]
 */
    ) throws -> T {
        //let readableRemoteDataType = remoteDataDocument.remoteDataReference.readableRemoteDataType(remoteDataDocument: remoteDataDocument)
        return try T(remoteDataDocument: remoteDataDocument)
        //return try readableRemoteDataType.init(remoteDataDocument: remoteDataDocument)
        /*
        return try readableRemoteDataType.init(
            dictionary: remoteDataDocument.dictionary,
            remoteDataReference: remoteDataDocument.remoteDataReference
        )
 */
        /*
        let readableRemoteDataType = remoteDataType.readableRemoteDataType
        return try readableRemoteDataType.init(
            dictionary: dictionary,
            remoteDataReference: remoteDataType
        )
 */
    }
    // DEPRECATE AND SIMPLY USE readableRemoteDataType.init()
    public func makeReadableRemoteDataFrom<T: ReadableRemoteData>(
        remoteDataDocument: RemoteDataDocument
        //dictionary: [String: Any]
    ) throws -> T {
        /*
        return try Self.makeReadableRemoteDataFrom(
            remoteDataType: self,
            dictionary: dictionary
        )
 */
        return try Self.makeReadableRemoteDataFrom(
            remoteDataDocument: remoteDataDocument
        )
    }
     */
}

extension RemoteDataReference {
    public var path: String {
        return documentReference.path
    }
}





